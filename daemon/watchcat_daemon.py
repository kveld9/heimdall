#!/usr/bin/env python3
"""
watchcat_daemon.py - Zero-Jank Telemetry Daemon for WatchCat System Monitor.
Collects kernel metrics, PSI, ZRAM compression, network quotas, process sockets,
and systemd unit health. Serves telemetry via low-overhead HTTP/JSON on 127.0.0.1:9871.
"""

import os
import sys
import time
import json
import shutil
import socket
import threading
import subprocess
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from collections import deque
from typing import Dict, Any, List, Optional

# Add daemon directory to path for local imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from storage import WatchCatStorage


class TelemetryEngine:
    def __init__(self):
        self.storage = WatchCatStorage()
        self.lock = threading.Lock()

        # Rolling history buffers for sparklines (30 points each)
        self.spark_len = 30
        self.history_net_down = deque([0.0] * self.spark_len, maxlen=self.spark_len)
        self.history_net_up = deque([0.0] * self.spark_len, maxlen=self.spark_len)
        self.history_cpu = deque([0.0] * self.spark_len, maxlen=self.spark_len)
        self.history_disk_read = deque([0.0] * self.spark_len, maxlen=self.spark_len)
        self.history_disk_write = deque([0.0] * self.spark_len, maxlen=self.spark_len)

        # Baseline state trackers
        self.prev_time = time.time()
        self.prev_net_counters = {}
        self.prev_cpu_counters = None
        self.prev_disk_counters = None
        self.prev_process_io = {}

        # Latest snapshot cache
        self.latest_telemetry: Dict[str, Any] = {}
        self.active_interface = self._detect_default_interface()

        # Initial collection
        self._update_all()

    def _detect_default_interface(self) -> str:
        """Detect the primary network interface from /proc/net/route or default route."""
        configured = self.storage.config.get("interface", "auto")
        if configured != "auto" and os.path.exists(f"/sys/class/net/{configured}"):
            return configured

        try:
            with open("/proc/net/route", "r") as f:
                for line in f.readlines()[1:]:
                    parts = line.strip().split()
                    if len(parts) >= 2 and parts[1] == "00000000":
                        return parts[0]
        except Exception:
            pass

        # Fallback to first non-loopback up interface
        try:
            for iface in os.listdir("/sys/class/net"):
                if iface != "lo":
                    operstate_path = f"/sys/class/net/{iface}/operstate"
                    if os.path.exists(operstate_path):
                        with open(operstate_path, "r") as f:
                            if f.read().strip() == "up":
                                return iface
        except Exception:
            pass
        return "enp7s0"

    def _read_file_safe(self, path: str) -> str:
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                return f.read()
        except Exception:
            return ""

    def _collect_net_rates(self, delta_t: float) -> Dict[str, Any]:
        """Read /proc/net/dev and calculate current speeds for active interface."""
        iface = self.active_interface
        content = self._read_file_safe("/proc/net/dev")
        current_rx = 0
        current_tx = 0
        found = False

        for line in content.splitlines():
            if ":" in line:
                name, data = line.split(":", 1)
                name = name.strip()
                if name == iface:
                    parts = data.split()
                    current_rx = int(parts[0])
                    current_tx = int(parts[8])
                    found = True
                    break

        if not found and content:
            # Re-detect active interface
            self.active_interface = self._detect_default_interface()
            iface = self.active_interface

        down_speed_bps = 0.0
        up_speed_bps = 0.0
        rx_delta = 0
        tx_delta = 0

        if iface in self.prev_net_counters and delta_t > 0:
            prev_rx, prev_tx = self.prev_net_counters[iface]
            if current_rx >= prev_rx:
                rx_delta = current_rx - prev_rx
                down_speed_bps = rx_delta / delta_t
            if current_tx >= prev_tx:
                tx_delta = current_tx - prev_tx
                up_speed_bps = tx_delta / delta_t

        self.prev_net_counters[iface] = (current_rx, current_tx)

        # Update persistent daily quota storage
        self.storage.record_traffic_delta(rx_delta, tx_delta, int(down_speed_bps + up_speed_bps))

        # Push to sparklines in KB/s
        self.history_net_down.append(round(down_speed_bps / 1024.0, 1))
        self.history_net_up.append(round(up_speed_bps / 1024.0, 1))

        return {
            "interface": iface,
            "down_rate_bps": int(down_speed_bps),
            "up_rate_bps": int(up_speed_bps),
            "down_rate_kb": round(down_speed_bps / 1024.0, 1),
            "up_rate_kb": round(up_speed_bps / 1024.0, 1),
            "sparkline_down": list(self.history_net_down),
            "sparkline_up": list(self.history_net_up)
        }

    def _collect_top_processes(self) -> List[Dict[str, Any]]:
        """Collect top network-active processes using ss -tupi and /proc/pid."""
        processes: Dict[int, Dict[str, Any]] = {}
        try:
            output = subprocess.check_output(
                ["ss", "-tupi"], stderr=subprocess.DEVNULL, timeout=0.8
            ).decode("utf-8", errors="ignore")

            for line in output.splitlines():
                if "users:((" in line:
                    idx = line.find("users:((")
                    users_str = line[idx:]
                    # Extract process name and pid: (("firefox",pid=51738,fd=...))
                    for part in users_str.split("),("):
                        try:
                            # clean tokens
                            clean = part.replace("users:((", "").replace("))", "").strip("()")
                            subparts = clean.split(",")
                            pname = subparts[0].strip('"\'')
                            pid = None
                            for sp in subparts[1:]:
                                if "pid=" in sp:
                                    pid = int(sp.split("=")[1])
                                    break
                            if pid and pid not in processes:
                                processes[pid] = {
                                    "pid": pid,
                                    "name": pname,
                                    "down_rate_kb": 0.0,
                                    "up_rate_kb": 0.0
                                }
                        except Exception:
                            continue
        except Exception:
            pass

        # Estimate throughput per process via /proc/<pid>/io deltas
        curr_proc_io = {}
        delta_t = max(0.5, time.time() - self.prev_time)
        res_list = []

        for pid, info in list(processes.items())[:12]:
            io_path = f"/proc/{pid}/io"
            if os.path.exists(io_path):
                try:
                    r_bytes, w_bytes = 0, 0
                    for l in self._read_file_safe(io_path).splitlines():
                        if l.startswith("read_bytes:"):
                            r_bytes = int(l.split()[1])
                        elif l.startswith("write_bytes:"):
                            w_bytes = int(l.split()[1])
                    curr_proc_io[pid] = (r_bytes, w_bytes)

                    if pid in self.prev_process_io:
                        pr_r, pr_w = self.prev_process_io[pid]
                        if r_bytes >= pr_r:
                            info["down_rate_kb"] = round((r_bytes - pr_r) / delta_t / 1024.0, 1)
                        if w_bytes >= pr_w:
                            info["up_rate_kb"] = round((w_bytes - pr_w) / delta_t / 1024.0, 1)
                except Exception:
                    pass
            res_list.append(info)

        self.prev_process_io = curr_proc_io
        # Sort by total activity descending
        res_list.sort(key=lambda x: x["down_rate_kb"] + x["up_rate_kb"], reverse=True)
        return res_list[:8]

    def _collect_compute(self, delta_t: float) -> Dict[str, Any]:
        """Collect CPU usage, RAM, ZRAM compression and PSI."""
        # CPU Usage
        cpu_usage = 0.0
        stat_content = self._read_file_safe("/proc/stat")
        if stat_content:
            first_line = stat_content.splitlines()[0]
            parts = [int(x) for x in first_line.split()[1:]]
            idle = parts[3] + parts[4]  # idle + iowait
            total = sum(parts)

            if self.prev_cpu_counters and delta_t > 0:
                prev_total, prev_idle = self.prev_cpu_counters
                total_d = total - prev_total
                idle_d = idle - prev_idle
                if total_d > 0:
                    cpu_usage = max(0.0, min(100.0, (1.0 - idle_d / total_d) * 100.0))

            self.prev_cpu_counters = (total, idle)

        self.history_cpu.append(round(cpu_usage, 1))

        # Memory info
        mem_info = {}
        for line in self._read_file_safe("/proc/meminfo").splitlines():
            if ":" in line:
                k, v = line.split(":", 1)
                val = v.strip().split()[0]
                try:
                    mem_info[k] = int(val) * 1024  # convert kB to Bytes
                except Exception:
                    pass

        total_ram = mem_info.get("MemTotal", 1)
        avail_ram = mem_info.get("MemAvailable", 0)
        used_ram = max(0, total_ram - avail_ram)

        # ZRAM compression (/sys/block/zram0/mm_stat)
        zram_stat = self._read_file_safe("/sys/block/zram0/mm_stat")
        zram_data = {
            "has_zram": False,
            "orig_size_bytes": 0,
            "compr_size_bytes": 0,
            "mem_used_bytes": 0,
            "ratio": 1.0,
            "savings_mb": 0.0
        }
        if zram_stat:
            tokens = zram_stat.split()
            if len(tokens) >= 3:
                try:
                    orig = int(tokens[0])
                    compr = int(tokens[1])
                    mem_used = int(tokens[2])
                    ratio = (orig / compr) if compr > 0 else 1.0
                    savings = max(0, orig - compr) / (1024.0 * 1024.0)
                    zram_data = {
                        "has_zram": True,
                        "orig_size_bytes": orig,
                        "compr_size_bytes": compr,
                        "mem_used_bytes": mem_used,
                        "ratio": round(ratio, 2),
                        "savings_mb": round(savings, 1)
                    }
                except Exception:
                    pass

        # PSI CPU & Memory
        psi_cpu = self._parse_psi("/proc/pressure/cpu")
        psi_mem = self._parse_psi("/proc/pressure/memory")

        return {
            "cpu_pct": round(cpu_usage, 1),
            "sparkline_cpu": list(self.history_cpu),
            "ram_total_bytes": total_ram,
            "ram_used_bytes": used_ram,
            "ram_pct": round((used_ram / total_ram) * 100.0, 1),
            "zram": zram_data,
            "psi_cpu": psi_cpu,
            "psi_mem": psi_mem
        }

    def _parse_psi(self, path: str) -> Dict[str, Any]:
        """Parse PSI stats (some/full avg10, avg60, avg300)."""
        content = self._read_file_safe(path)
        data = {
            "some_avg10": 0.0, "some_avg60": 0.0, "some_avg300": 0.0,
            "full_avg10": 0.0, "full_avg60": 0.0, "full_avg300": 0.0
        }
        for line in content.splitlines():
            parts = line.split()
            if not parts:
                continue
            prefix = parts[0]  # 'some' or 'full'
            for item in parts[1:]:
                if "=" in item:
                    k, v = item.split("=", 1)
                    if k in ["avg10", "avg60", "avg300"]:
                        try:
                            data[f"{prefix}_{k}"] = float(v)
                        except Exception:
                            pass
        return data

    def _collect_storage(self, delta_t: float) -> Dict[str, Any]:
        """Collect disk I/O rates and mounted partition usage."""
        read_mb_s = 0.0
        write_mb_s = 0.0

        # Read /proc/diskstats
        content = self._read_file_safe("/proc/diskstats")
        total_sectors_read = 0
        total_sectors_written = 0

        for line in content.splitlines():
            parts = line.split()
            if len(parts) >= 14:
                dev_name = parts[2]
                # Filter to physical drives like nvme0n1, sda
                if dev_name.startswith("nvme") and "p" not in dev_name:
                    total_sectors_read += int(parts[5])
                    total_sectors_written += int(parts[9])
                elif (dev_name.startswith("sd") or dev_name.startswith("vd")) and not dev_name[-1].isdigit():
                    total_sectors_read += int(parts[5])
                    total_sectors_written += int(parts[9])

        if self.prev_disk_counters and delta_t > 0:
            prev_r, prev_w = self.prev_disk_counters
            if total_sectors_read >= prev_r:
                read_bytes = (total_sectors_read - prev_r) * 512
                read_mb_s = (read_bytes / delta_t) / (1024.0 * 1024.0)
            if total_sectors_written >= prev_w:
                write_bytes = (total_sectors_written - prev_w) * 512
                write_mb_s = (write_bytes / delta_t) / (1024.0 * 1024.0)

        self.prev_disk_counters = (total_sectors_read, total_sectors_written)

        self.history_disk_read.append(round(read_mb_s, 2))
        self.history_disk_write.append(round(write_mb_s, 2))

        # Partitions
        partitions = []
        for mount in ["/", "/home"]:
            if os.path.exists(mount):
                try:
                    usage = shutil.disk_usage(mount)
                    pct = round((usage.used / usage.total) * 100.0, 1)
                    partitions.append({
                        "mount": mount,
                        "total_gb": round(usage.total / (1024.0 ** 3), 1),
                        "used_gb": round(usage.used / (1024.0 ** 3), 1),
                        "free_gb": round(usage.free / (1024.0 ** 3), 1),
                        "used_pct": pct
                    })
                except Exception:
                    pass

        psi_io = self._parse_psi("/proc/pressure/io")

        return {
            "read_mb_s": round(read_mb_s, 2),
            "write_mb_s": round(write_mb_s, 2),
            "sparkline_read": list(self.history_disk_read),
            "sparkline_write": list(self.history_disk_write),
            "partitions": partitions,
            "psi_io": psi_io
        }

    def _collect_systemd_and_health(self) -> Dict[str, Any]:
        """Collect failed units count, sensors, and timers."""
        failed_count = 0
        failed_units = []

        # Check DBus or systemctl for NFailedUnits
        try:
            out = subprocess.check_output(
                ["systemctl", "is-system-running"], stderr=subprocess.DEVNULL, timeout=0.5
            ).decode().strip()
        except subprocess.CalledProcessError as e:
            out = e.output.decode().strip() if e.output else "degraded"
        except Exception:
            out = "running"

        try:
            fout = subprocess.check_output(
                ["systemctl", "--failed", "--no-legend", "--plain"], stderr=subprocess.DEVNULL, timeout=0.5
            ).decode().strip()
            if fout:
                lines = fout.splitlines()
                failed_count = len(lines)
                for l in lines[:4]:
                    parts = l.split()
                    if parts:
                        failed_units.append(parts[0])
        except Exception:
            pass

        # Thermal Sensors
        temps = []
        hwmon_dir = "/sys/class/hwmon"
        if os.path.exists(hwmon_dir):
            for entry in sorted(os.listdir(hwmon_dir)):
                h_path = os.path.join(hwmon_dir, entry)
                name = self._read_file_safe(os.path.join(h_path, "name")).strip() or entry
                for f in os.listdir(h_path):
                    if f.startswith("temp") and f.endswith("_input"):
                        val_str = self._read_file_safe(os.path.join(h_path, f)).strip()
                        if val_str.isdigit():
                            celsius = round(int(val_str) / 1000.0, 1)
                            label_file = f.replace("_input", "_label")
                            label = self._read_file_safe(os.path.join(h_path, label_file)).strip() or name
                            temps.append({"label": f"{name}: {label}", "celsius": celsius})
                            break

        return {
            "system_state": out,
            "failed_units_count": failed_count,
            "failed_units": failed_units,
            "thermal_sensors": temps[:5]
        }

    def _update_all(self):
        """Perform a single round of telemetry collection."""
        curr_time = time.time()
        delta_t = max(0.1, curr_time - self.prev_time)

        net_data = self._collect_net_rates(delta_t)
        top_procs = self._collect_top_processes()
        compute_data = self._collect_compute(delta_t)
        storage_data = self._collect_storage(delta_t)
        systemd_data = self._collect_systemd_and_health()
        budget_summary = self.storage.get_today_summary()
        weekly_breakdown = self.storage.get_weekly_breakdown()

        self.prev_time = curr_time

        with self.lock:
            self.latest_telemetry = {
                "timestamp": curr_time,
                "datetime_iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(curr_time)),
                "date_display": time.strftime("%a, %d %b"),
                "time_display": time.strftime("%H:%M"),
                "net": net_data,
                "budget": budget_summary,
                "weekly": weekly_breakdown,
                "processes": top_procs,
                "compute": compute_data,
                "storage": storage_data,
                "health": systemd_data,
                "config": self.storage.config
            }

    def get_snapshot(self) -> Dict[str, Any]:
        with self.lock:
            return self.latest_telemetry

    def loop(self):
        """Sampling thread running at 1-second intervals."""
        while True:
            try:
                self._update_all()
            except Exception as e:
                print(f"[WatchCat] Telemetry loop exception: {e}")
            time.sleep(1.0)


class WatchCatHTTPHandler(BaseHTTPRequestHandler):
    engine: TelemetryEngine = None

    def _send_json(self, status: int, data: Any):
        body = json.dumps(data, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        if self.path in ["/api/telemetry", "/api/all", "/"]:
            self._send_json(200, self.engine.get_snapshot())
        elif self.path == "/api/budget":
            self._send_json(200, self.engine.storage.get_today_summary())
        elif self.path == "/api/week":
            self._send_json(200, self.engine.storage.get_weekly_breakdown())
        elif self.path == "/health":
            self._send_json(200, {"status": "ok", "service": "watchcat-daemon"})
        else:
            self._send_json(404, {"error": "Not Found"})

    def do_POST(self):
        if self.path == "/api/config":
            try:
                content_len = int(self.headers.get("Content-Length", 0))
                payload = json.loads(self.rfile.read(content_len).decode("utf-8"))
                for k in ["daily_cap_bytes", "warning_threshold_bytes", "interface", "theme_mode"]:
                    if k in payload:
                        self.engine.storage.config[k] = payload[k]
                self.engine.storage._save_config()
                self._send_json(200, {"status": "updated", "config": self.engine.storage.config})
            except Exception as e:
                self._send_json(400, {"error": str(e)})
        else:
            self._send_json(404, {"error": "Not Found"})

    def log_message(self, format, *args):
        # Silence routine request logging to prevent terminal clutter
        pass


def run_daemon(host: str = "127.0.0.1", port: int = 9871):
    engine = TelemetryEngine()
    WatchCatHTTPHandler.engine = engine

    # Start sampling background thread
    t = threading.Thread(target=engine.loop, daemon=True)
    t.start()

    server = ThreadingHTTPServer((host, port), WatchCatHTTPHandler)
    print(f"[*] WatchCat Telemetry Daemon listening on http://{host}:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Stopping WatchCat Daemon...")
    finally:
        server.server_close()


if __name__ == "__main__":
    port = int(os.environ.get("WATCHCAT_PORT", 9871))
    run_daemon(port=port)
