"""Systemd units, scheduled timers, system vitals, and thermal sensor collector."""

import json
import os
import subprocess
import time
from typing import Any, Dict, List

from .base import BaseCollector


def _format_countdown(diff_seconds: float) -> str:
    """Format positive time delta into compact human countdown string."""
    total_sec = max(0, int(diff_seconds))
    days = total_sec // 86400
    hours = (total_sec % 86400) // 3600
    mins = (total_sec % 3600) // 60
    if days > 0:
        return f"{days}d {hours}h"
    if hours > 0:
        return f"{hours}h {mins}m"
    return f"{mins}m"



class HealthCollector(BaseCollector):
    """Collects failed units, upcoming timers, uptime, loadavg, OOM terminations, and thermals."""

    def read_systemd_status(self) -> Dict[str, Any]:
        """Query systemctl for degraded or failed units."""
        failed_count = 0
        failed_units: List[str] = []
        system_state = "running"

        try:
            res_state = subprocess.run(
                ["systemctl", "is-system-running"],
                capture_output=True,
                text=True,
                timeout=0.6,
                check=False
            )
            system_state = res_state.stdout.strip() or "running"

            res_failed = subprocess.run(
                ["systemctl", "--failed", "--no-legend", "--plain"],
                capture_output=True,
                text=True,
                timeout=0.6,
                check=False
            )
            for line in res_failed.stdout.splitlines():
                parts = line.strip().split()
                if len(parts) >= 2 and (parts[0].endswith(".service") or parts[0].endswith(".target")):
                    failed_units.append(parts[0])
            failed_count = len(failed_units)
        except Exception:
            pass

        return {
            "failed_units_count": failed_count,
            "failed_units": failed_units[:5],
            "system_state": system_state,
        }

    def read_systemd_timers(self) -> List[Dict[str, str]]:
        """Query upcoming scheduled timers via systemctl list-timers."""
        now = time.time()
        timers: List[Dict[str, str]] = []
        try:
            res = subprocess.run(
                ["systemctl", "list-timers", "--output=json", "--no-pager"],
                capture_output=True,
                text=True,
                timeout=0.8,
                check=False
            )
            if res.returncode == 0 and res.stdout.strip():
                data = json.loads(res.stdout)
                for item in data:
                    unit = str(item.get("unit", ""))
                    next_us = item.get("next", 0)
                    activates = str(item.get("activates", ""))
                    if not unit or not next_us:
                        continue
                    diff_sec = (float(next_us) / 1_000_000.0) - now
                    if diff_sec <= 0:
                        continue
                    short_unit = unit.replace(".timer", "")
                    timers.append({
                        "unit": short_unit,
                        "left_str": _format_countdown(diff_sec),
                        "activates": activates,
                    })
                if timers:
                    return timers[:4]
        except Exception:
            pass

        # Fallback to legendless full output
        try:
            res_plain = subprocess.run(
                ["systemctl", "list-timers", "--no-legend", "--full", "--no-pager"],
                capture_output=True,
                text=True,
                timeout=0.8,
                check=False
            )
            for line in res_plain.stdout.splitlines():
                parts = line.strip().split()
                if len(parts) >= 6 and ".timer" in line:
                    for idx, part in enumerate(parts):
                        if part.endswith(".timer"):
                            unit_name = part.replace(".timer", "")
                            activates = parts[idx + 1] if idx + 1 < len(parts) else ""
                            timers.append({
                                "unit": unit_name,
                                "left_str": "soon",
                                "activates": activates,
                            })
                            break
        except Exception:
            pass

        return timers[:4]

    def read_vitals(self) -> Dict[str, Any]:
        """Read host uptime, load average, logical CPU core count, and kernel OOM kill count."""
        uptime_str = "0m"
        try:
            with open("/proc/uptime", "r", encoding="utf-8") as f:
                secs = float(f.read().split()[0])
                days = int(secs // 86400)
                hrs = int((secs % 86400) // 3600)
                mins = int((secs % 3600) // 60)
                if days > 0:
                    uptime_str = f"{days}d {hrs}h"
                elif hrs > 0:
                    uptime_str = f"{hrs}h {mins}m"
                else:
                    uptime_str = f"{mins}m"
        except Exception:
            pass

        loadavg = ["0.00", "0.00", "0.00"]
        try:
            with open("/proc/loadavg", "r", encoding="utf-8") as f:
                parts = f.read().split()
                if len(parts) >= 3:
                    loadavg = [parts[0], parts[1], parts[2]]
        except Exception:
            pass

        cpu_cores = os.cpu_count() or 1

        oom_count = 0
        try:
            with open("/proc/vmstat", "r", encoding="utf-8") as f:
                for line in f:
                    if line.startswith("oom_kill"):
                        oom_count = int(line.split()[1])
                        break
        except Exception:
            pass

        return {
            "uptime_str": uptime_str,
            "loadavg": loadavg,
            "cpu_cores": cpu_cores,
            "oom_count": oom_count,
        }

    def read_thermals(self) -> List[Dict[str, Any]]:
        """Read temperature sensors from /sys/class/hwmon."""
        sensors = []
        hwmon_dir = "/sys/class/hwmon"
        if os.path.isdir(hwmon_dir):
            try:
                for entry in sorted(os.listdir(hwmon_dir)):
                    dev_path = os.path.join(hwmon_dir, entry)
                    name_file = os.path.join(dev_path, "name")
                    name = "Sensor"
                    if os.path.isfile(name_file):
                        try:
                            with open(name_file, "r", encoding="utf-8") as nf:
                                name = nf.read().strip()
                        except Exception:
                            pass

                    for sub in sorted(os.listdir(dev_path)):
                        if sub.startswith("temp") and sub.endswith("_input"):
                            idx = sub.split("_")[0]
                            label_file = os.path.join(dev_path, f"{idx}_label")
                            label = name
                            if os.path.isfile(label_file):
                                try:
                                    with open(label_file, "r", encoding="utf-8") as lf:
                                        label = f"{name} {lf.read().strip()}"
                                except Exception:
                                    pass

                            temp_file = os.path.join(dev_path, sub)
                            try:
                                with open(temp_file, "r", encoding="utf-8") as tf:
                                    raw_temp = int(tf.read().strip())
                                    celsius = raw_temp / 1000.0
                                    sensors.append({
                                        "label": label[:16],
                                        "celsius": round(celsius, 1),
                                    })
                            except Exception:
                                pass
            except Exception:
                pass

        return sensors[:6]

    def collect(self) -> Dict[str, Any]:
        """Collect combined health, scheduler, and hardware thermal metrics."""
        systemd = self.read_systemd_status()
        timers = self.read_systemd_timers()
        vitals = self.read_vitals()
        thermals = self.read_thermals()

        return {
            "failed_units_count": systemd["failed_units_count"],
            "failed_units": systemd["failed_units"],
            "system_state": systemd["system_state"],
            "timers": timers,
            "uptime_str": vitals["uptime_str"],
            "loadavg": vitals["loadavg"],
            "cpu_cores": vitals["cpu_cores"],
            "oom_count": vitals["oom_count"],
            "thermal_sensors": thermals,
        }

