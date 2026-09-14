"""Systemd units, scheduled timers, system vitals, and thermal sensor collector."""

import json
import os
import subprocess
import time
from collections import deque
from typing import Any, Dict, List

from .base import BaseCollector


def _read_file(path: str, default: str = "") -> str:
    """Safely read and strip single-line file from filesystem."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read().strip()
    except Exception:
        return default


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

    def __init__(self) -> None:
        super().__init__()
        self.sparkline_temp: deque = deque([0.0] * 30, maxlen=30)

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
            "failed_units": failed_units[:25],
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
                    return timers[:8]
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

        return timers[:8]

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

    def read_hwmon(self) -> Dict[str, Any]:
        """Read temperatures, fans, voltages, and maintain temp sparkline from hwmon."""
        sensors: List[Dict[str, Any]] = []
        fans: List[Dict[str, Any]] = []
        voltages: List[Dict[str, Any]] = []
        max_c = 0.0
        hwmon_dir = "/sys/class/hwmon"
        if os.path.isdir(hwmon_dir):
            try:
                for entry in sorted(os.listdir(hwmon_dir)):
                    dev_path = os.path.join(hwmon_dir, entry)
                    name = _read_file(os.path.join(dev_path, "name"), "Sensor")
                    for sub in sorted(os.listdir(dev_path)):
                        idx = sub.split("_")[0]
                        lbl = _read_file(os.path.join(dev_path, f"{idx}_label"))
                        if sub.startswith("temp") and sub.endswith("_input"):
                            val_str = _read_file(os.path.join(dev_path, sub))
                            crit_str = _read_file(os.path.join(dev_path, f"{idx}_crit"))
                            if val_str.lstrip("-").isdigit():
                                c = int(val_str) / 1000.0
                                crit = int(crit_str) / 1000.0 if crit_str.isdigit() else 100.0
                                full_lbl = f"{name} {lbl}".strip() if lbl else name
                                sensors.append({"label": full_lbl[:16], "celsius": round(c, 1), "crit": round(crit, 1)})
                                if c > max_c:
                                    max_c = c
                        elif sub.startswith("fan") and sub.endswith("_input"):
                            rpm_str = _read_file(os.path.join(dev_path, sub))
                            if rpm_str.isdigit():
                                full_lbl = f"{name} {lbl}".strip() if lbl else f"{name} Fan"
                                fans.append({"label": full_lbl[:16], "rpm": int(rpm_str)})
                        elif sub.startswith("in") and sub.endswith("_input"):
                            mv_str = _read_file(os.path.join(dev_path, sub))
                            if mv_str.isdigit():
                                full_lbl = f"{name} {lbl}".strip() if lbl else f"{name} In"
                                voltages.append({"label": full_lbl[:16], "volts": round(int(mv_str) / 1000.0, 2)})
            except Exception:
                pass

        if max_c > 0:
            self.sparkline_temp.append(round(max_c, 1))
        elif sensors:
            self.sparkline_temp.append(sensors[0]["celsius"])
        else:
            self.sparkline_temp.append(0.0)

        return {
            "sensors": sensors[:6],
            "fans": fans[:4],
            "voltages": voltages[:4],
            "sparkline_temp": list(self.sparkline_temp),
        }

    def collect(self) -> Dict[str, Any]:
        """Collect combined health, scheduler, and hardware thermal metrics."""
        systemd = self.read_systemd_status()
        timers = self.read_systemd_timers()
        vitals = self.read_vitals()
        hw = self.read_hwmon()

        return {
            "failed_units_count": systemd["failed_units_count"],
            "failed_units": systemd["failed_units"],
            "system_state": systemd["system_state"],
            "timers": timers,
            "uptime_str": vitals["uptime_str"],
            "loadavg": vitals["loadavg"],
            "cpu_cores": vitals["cpu_cores"],
            "oom_count": vitals["oom_count"],
            "thermal_sensors": hw["sensors"],
            "fan_sensors": hw["fans"],
            "voltage_sensors": hw["voltages"],
            "sparkline_temp": hw["sparkline_temp"],
        }

