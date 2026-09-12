"""CPU utilization, RAM, ZRAM capacity, PSI, and top compute process collector."""

import os
import subprocess
from collections import deque
from typing import Any, Dict, List, Optional, Tuple

from .base import BaseCollector


class ComputeCollector(BaseCollector):
    """Collects CPU percentage, memory allocation, ZRAM compression, and PSI."""

    def __init__(self, sparkline_points: int = 60) -> None:
        self.sparkline_points = sparkline_points
        self.prev_cpu_total: Optional[int] = None
        self.prev_cpu_idle: Optional[int] = None
        self.sparkline_cpu: deque = deque([0.0] * sparkline_points, maxlen=sparkline_points)

    def read_cpu_pct(self) -> float:
        """Calculate non-idle tick delta from /proc/stat."""
        try:
            with open("/proc/stat", "r", encoding="utf-8") as f:
                first_line = f.readline()
                if first_line.startswith("cpu "):
                    parts = [int(x) for x in first_line.split()[1:]]
                    idle = parts[3] + (parts[4] if len(parts) > 4 else 0)
                    total = sum(parts)

                    pct = 0.0
                    if self.prev_cpu_total is not None and total > self.prev_cpu_total:
                        d_total = total - self.prev_cpu_total
                        d_idle = idle - self.prev_cpu_idle
                        pct = max(0.0, min(100.0, (1.0 - (d_idle / d_total)) * 100.0))

                    self.prev_cpu_total = total
                    self.prev_cpu_idle = idle
                    return pct
        except Exception:
            pass
        return 0.0

    def read_ram(self) -> Tuple[int, int, float]:
        """Extract MemTotal, MemAvailable and compute used percentage."""
        total = 0
        available = 0
        try:
            with open("/proc/meminfo", "r", encoding="utf-8") as f:
                for line in f:
                    if line.startswith("MemTotal:"):
                        total = int(line.split()[1]) * 1024
                    elif line.startswith("MemAvailable:"):
                        available = int(line.split()[1]) * 1024
        except Exception:
            pass

        used = max(0, total - available)
        pct = (used / total * 100.0) if total > 0 else 0.0
        return total, used, pct

    def read_zram(self) -> Dict[str, Any]:
        """Read ZRAM compression statistics and device pool capacity."""
        mm_stat_path = "/sys/block/zram0/mm_stat"
        disksize_path = "/sys/block/zram0/disksize"
        if not os.path.isfile(mm_stat_path):
            return {"has_zram": False, "ratio": 1.0, "savings_mb": 0.0, "capacity_bytes": 0, "usage_pct": 0.0}

        try:
            capacity_bytes = 0
            if os.path.isfile(disksize_path):
                with open(disksize_path, "r", encoding="utf-8") as df:
                    capacity_bytes = int(df.read().strip())

            with open(mm_stat_path, "r", encoding="utf-8") as f:
                fields = f.read().strip().split()
                if len(fields) >= 3:
                    orig_size = int(fields[0])
                    compr_size = int(fields[1])
                    mem_used = int(fields[2])

                    ratio = (orig_size / compr_size) if compr_size > 0 else 1.0
                    savings_mb = max(0, (orig_size - compr_size) / (1024 * 1024))
                    usage_pct = (compr_size / capacity_bytes * 100.0) if capacity_bytes > 0 else 0.0

                    return {
                        "has_zram": True,
                        "capacity_bytes": capacity_bytes,
                        "orig_size_bytes": orig_size,
                        "compr_size_bytes": compr_size,
                        "mem_used_bytes": mem_used,
                        "ratio": round(ratio, 2),
                        "savings_mb": round(savings_mb, 1),
                        "usage_pct": round(usage_pct, 2),
                    }
        except Exception:
            pass

        return {"has_zram": False, "ratio": 1.0, "savings_mb": 0.0, "capacity_bytes": 0, "usage_pct": 0.0}

    def read_psi(self, path: str) -> Dict[str, float]:
        """Parse Pressure Stall Information (PSI) averages."""
        res: Dict[str, float] = {
            "some_avg10": 0.0,
            "some_avg60": 0.0,
            "some_avg300": 0.0,
            "full_avg10": 0.0,
            "full_avg60": 0.0,
            "full_avg300": 0.0,
        }
        if not os.path.isfile(path):
            return res

        try:
            with open(path, "r", encoding="utf-8") as f:
                for line in f:
                    parts = line.strip().split()
                    prefix = parts[0]
                    for token in parts[1:]:
                        if "=" in token:
                            k, v = token.split("=")
                            key = f"{prefix}_{k}"
                            if key in res:
                                res[key] = float(v)
        except Exception:
            pass
        return res

    def collect_top_processes(self) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
        """Collect top 3 CPU and top 3 RAM processes aggregated by comm."""
        try:
            res = subprocess.run(
                ["ps", "-eo", "comm,%cpu,%mem,rss", "--no-headers", "--sort=-%cpu"],
                capture_output=True,
                text=True,
                timeout=0.6,
                check=False
            )
            aggregated: Dict[str, Dict[str, Any]] = {}
            for line in res.stdout.splitlines():
                parts = line.strip().split()
                if len(parts) >= 4:
                    comm = parts[0]
                    try:
                        cpu_pct = float(parts[1])
                        rss_kb = int(parts[3])
                    except ValueError:
                        continue

                    if comm not in aggregated:
                        aggregated[comm] = {
                            "name": comm,
                            "cpu_pct": 0.0,
                            "rss_mb": 0.0,
                            "instances": 0,
                        }
                    aggregated[comm]["cpu_pct"] += cpu_pct
                    aggregated[comm]["rss_mb"] += (rss_kb / 1024.0)
                    aggregated[comm]["instances"] += 1

            for item in aggregated.values():
                item["cpu_pct"] = round(item["cpu_pct"], 1)
                item["rss_mb"] = round(item["rss_mb"], 1)

            sorted_by_cpu = sorted(aggregated.values(), key=lambda x: x["cpu_pct"], reverse=True)[:3]
            sorted_by_mem = sorted(aggregated.values(), key=lambda x: x["rss_mb"], reverse=True)[:3]
            return sorted_by_cpu, sorted_by_mem
        except Exception:
            return [], []

    def collect(self) -> Dict[str, Any]:
        """Collect snapshot of all compute metrics."""
        cpu_pct = self.read_cpu_pct()
        self.sparkline_cpu.append(round(cpu_pct, 1))

        ram_total, ram_used, ram_pct = self.read_ram()
        zram_stat = self.read_zram()
        psi_cpu = self.read_psi("/proc/pressure/cpu")
        psi_mem = self.read_psi("/proc/pressure/memory")
        top_cpu, top_mem = self.collect_top_processes()

        return {
            "cpu_pct": round(cpu_pct, 1),
            "ram_pct": round(ram_pct, 1),
            "ram_total_bytes": ram_total,
            "ram_used_bytes": ram_used,
            "sparkline_cpu": list(self.sparkline_cpu),
            "zram": zram_stat,
            "psi_cpu": psi_cpu,
            "psi_mem": psi_mem,
            "top_cpu": top_cpu,
            "top_mem": top_mem,
        }
