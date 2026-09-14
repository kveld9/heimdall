"""Network rate, interface, and per-process socket telemetry collector."""

import os
import re
import subprocess
import time
from collections import deque
from typing import Any, Dict, List, Optional, Tuple

from .base import BaseCollector


class NetworkCollector(BaseCollector):
    """Collects network throughput, active interfaces, and socket-owning processes."""

    def __init__(self, interface: Optional[str] = None, sparkline_points: int = 30) -> None:
        self.interface = interface
        self.sparkline_points = sparkline_points
        self.prev_time: Optional[float] = None
        self.prev_rx_bytes = 0
        self.prev_tx_bytes = 0
        self.sparkline_down: deque = deque([0.0] * sparkline_points, maxlen=sparkline_points)
        self.sparkline_up: deque = deque([0.0] * sparkline_points, maxlen=sparkline_points)
        self.prev_proc_io: Dict[str, Tuple[float, int]] = {}

    def detect_default_interface(self) -> str:
        """Find the active default route interface from /proc/net/route."""
        if self.interface:
            return self.interface
        try:
            with open("/proc/net/route", "r", encoding="utf-8") as f:
                for line in f.readlines()[1:]:
                    parts = line.strip().split()
                    if len(parts) >= 2 and parts[1] == "00000000":
                        return parts[0]
        except Exception:
            pass

        # Fallback to first up interface in /sys/class/net
        try:
            for iface in os.listdir("/sys/class/net"):
                if iface == "lo":
                    continue
                operstate_path = f"/sys/class/net/{iface}/operstate"
                if os.path.isfile(operstate_path):
                    with open(operstate_path, "r", encoding="utf-8") as f:
                        if f.read().strip() == "up":
                            return iface
        except Exception:
            pass

        try:
            devices = [i for i in os.listdir("/sys/class/net") if i != "lo"]
            if devices:
                return sorted(devices)[0]
        except Exception:
            pass

        return "eth0"

    def read_interface_bytes(self, iface: str) -> Tuple[int, int]:
        """Read cumulative rx and tx bytes for iface from /proc/net/dev."""
        try:
            with open("/proc/net/dev", "r", encoding="utf-8") as f:
                for line in f:
                    if ":" in line:
                        name, data = line.split(":", 1)
                        if name.strip() == iface:
                            fields = data.split()
                            return int(fields[0]), int(fields[8])
        except Exception:
            pass
        return 0, 0

    def collect_grouped_processes(self) -> List[Dict[str, Any]]:
        """Collect and group network processes by binary name using ss and /proc/<pid>/io."""
        grouped: Dict[str, Dict[str, Any]] = {}
        try:
            res = subprocess.run(
                ["ss", "-tupi"],
                capture_output=True,
                text=True,
                timeout=0.8,
                check=False
            )
            seen_pids = set()
            for line in res.stdout.splitlines():
                matches = re.findall(r'users:\(\("([^"]+)",pid=(\d+)', line)
                for name, pid_str in matches:
                    pid = int(pid_str)
                    clean_name = name.split("/")[-1].split(" ")[0]
                    if not clean_name:
                        continue

                    if clean_name not in grouped:
                        grouped[clean_name] = {
                            "name": clean_name,
                            "instances": 0,
                            "pids": set(),
                            "read_bytes": 0,
                            "write_bytes": 0,
                        }

                    if pid not in seen_pids:
                        seen_pids.add(pid)
                        grouped[clean_name]["instances"] += 1
                        grouped[clean_name]["pids"].add(pid)

                        io_path = f"/proc/{pid}/io"
                        if os.path.isfile(io_path):
                            try:
                                with open(io_path, "r", encoding="utf-8") as iof:
                                    for ioline in iof:
                                        if ioline.startswith("read_bytes:"):
                                            grouped[clean_name]["read_bytes"] += int(ioline.split()[1])
                                        elif ioline.startswith("write_bytes:"):
                                            grouped[clean_name]["write_bytes"] += int(ioline.split()[1])
                            except Exception:
                                pass

            now = time.time()
            results = []
            for item in grouped.values():
                total_io = item["read_bytes"] + item["write_bytes"]
                rate_str = "0 KB/s"
                cname = item["name"]
                if cname in self.prev_proc_io:
                    prev_t, prev_tot = self.prev_proc_io[cname]
                    dt = now - prev_t
                    if dt > 0.3 and total_io >= prev_tot:
                        rate_bps = (total_io - prev_tot) / dt
                        rate_kb = rate_bps / 1024.0
                        if rate_kb < 1024:
                            rate_str = f"{int(round(rate_kb))} KB/s"
                        else:
                            rate_str = f"{rate_kb / 1024.0:.1f} MB/s"
                self.prev_proc_io[cname] = (now, total_io)

                results.append({
                    "name": item["name"],
                    "instances": item["instances"],
                    "rate_str": rate_str,
                    "total_io_mb": round(total_io / (1024 * 1024), 1),
                    "read_mb": round(item["read_bytes"] / (1024 * 1024), 1),
                    "write_mb": round(item["write_bytes"] / (1024 * 1024), 1),
                })
            results.sort(key=lambda x: x["total_io_mb"], reverse=True)
            return results[:6]
        except Exception:
            return []

    def collect(self) -> Dict[str, Any]:
        """Compute instantaneous speeds and gather socket state."""
        now = time.time()
        iface = self.detect_default_interface()
        rx, tx = self.read_interface_bytes(iface)

        down_rate_kb = 0.0
        up_rate_kb = 0.0
        delta_rx = 0
        delta_tx = 0

        if self.prev_time is not None and now > self.prev_time:
            dt = now - self.prev_time
            if rx >= self.prev_rx_bytes and self.prev_rx_bytes > 0:
                delta_rx = rx - self.prev_rx_bytes
                down_rate_kb = (delta_rx / dt) / 1024.0
            if tx >= self.prev_tx_bytes and self.prev_tx_bytes > 0:
                delta_tx = tx - self.prev_tx_bytes
                up_rate_kb = (delta_tx / dt) / 1024.0

        self.prev_time = now
        self.prev_rx_bytes = rx
        self.prev_tx_bytes = tx

        self.sparkline_down.append(round(down_rate_kb, 1))
        self.sparkline_up.append(round(up_rate_kb, 1))

        top_processes = self.collect_grouped_processes()

        return {
            "interface": iface,
            "down_rate_kb": round(down_rate_kb, 1),
            "up_rate_kb": round(up_rate_kb, 1),
            "sparkline_down": list(self.sparkline_down),
            "sparkline_up": list(self.sparkline_up),
            "top_processes": top_processes,
            "delta_rx": delta_rx,
            "delta_tx": delta_tx,
        }
