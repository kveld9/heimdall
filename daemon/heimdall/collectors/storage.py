"""Storage throughput, mounted filesystem pools, and top disk I/O collector."""

import os
import time
from collections import deque
from typing import Any, Dict, List, Optional, Tuple

from .base import BaseCollector


class StorageCollector(BaseCollector):
    """Collects disk read/write throughput, deduplicated partitions, and disk PSI."""

    def __init__(self, sparkline_points: int = 30) -> None:
        self.sparkline_points = sparkline_points
        self.prev_time: Optional[float] = None
        self.prev_sectors_read: int = 0
        self.prev_sectors_written: int = 0
        self.sparkline_read: deque = deque(maxlen=sparkline_points)
        self.sparkline_write: deque = deque(maxlen=sparkline_points)

    def read_disk_throughput(self) -> Tuple[float, float]:
        """Parse /proc/diskstats for primary block devices and compute MB/s."""
        sectors_read = 0
        sectors_written = 0
        now = time.time()

        try:
            with open("/proc/diskstats", "r", encoding="utf-8") as f:
                for line in f:
                    parts = line.strip().split()
                    if len(parts) >= 14:
                        dev = parts[2]
                        if dev.startswith("nvme") and "p" not in dev:
                            sectors_read += int(parts[5])
                            sectors_written += int(parts[9])
                        elif (dev.startswith("sd") or dev.startswith("vd")) and not any(c.isdigit() for c in dev[2:]):
                            sectors_read += int(parts[5])
                            sectors_written += int(parts[9])
        except Exception:
            pass

        read_mb_s = 0.0
        write_mb_s = 0.0
        if self.prev_time is not None and now > self.prev_time:
            dt = now - self.prev_time
            if sectors_read >= self.prev_sectors_read and self.prev_sectors_read > 0:
                read_mb_s = ((sectors_read - self.prev_sectors_read) * 512) / (1024 * 1024 * dt)
            if sectors_written >= self.prev_sectors_written and self.prev_sectors_written > 0:
                write_mb_s = ((sectors_written - self.prev_sectors_written) * 512) / (1024 * 1024 * dt)

        self.prev_time = now
        self.prev_sectors_read = sectors_read
        self.prev_sectors_written = sectors_written

        return round(read_mb_s, 2), round(write_mb_s, 2)

    def read_partitions(self) -> List[Dict[str, Any]]:
        """Query mounted filesystem pools deduplicating identical physical storage devices."""
        partitions = []
        candidate_mounts = [("/", "Root & Home (/)")]

        # Discover secondary disks mounted under /mnt, /media, /run/media, /home
        try:
            with open("/proc/mounts", "r", encoding="utf-8") as f:
                for line in f:
                    parts = line.split()
                    if len(parts) >= 2:
                        dev, target = parts[0], parts[1]
                        if not dev.startswith("/dev/"):
                            continue
                        if target in ("/boot", "/efi", "/boot/efi"):
                            continue
                        if target.startswith(("/mnt/", "/media/", "/run/media/")) or target == "/home":
                            label = target.split("/")[-1] if target != "/home" else "Home (/home)"
                            candidate_mounts.append((target, label))
        except Exception:
            pass

        seen_devices = set()
        for path, label in candidate_mounts:
            if not os.path.isdir(path):
                continue
            try:
                st_dev = os.stat(path).st_dev
                if st_dev in seen_devices:
                    continue
                seen_devices.add(st_dev)

                st = os.statvfs(path)
                total_bytes = st.f_blocks * st.f_frsize
                free_bytes = st.f_bavail * st.f_frsize
                used_bytes = total_bytes - free_bytes

                # Ignore boot partitions under 5 GB unless root
                if total_bytes < 5 * (1024**3) and path != "/":
                    continue

                if total_bytes > 0:
                    partitions.append({
                        "mount": label,
                        "total_gb": round(total_bytes / (1024**3), 1),
                        "used_gb": round(used_bytes / (1024**3), 1),
                        "free_gb": round(free_bytes / (1024**3), 1),
                        "used_pct": round(used_bytes / total_bytes * 100.0, 1),
                    })
            except Exception:
                pass

        return partitions

    def collect_top_disk_io(self) -> List[Dict[str, Any]]:
        """Identify top 3 user processes generating disk I/O."""
        aggregated: Dict[str, Dict[str, Any]] = {}
        try:
            for pid_dir in os.listdir("/proc"):
                if not pid_dir.isdigit():
                    continue
                comm_path = f"/proc/{pid_dir}/comm"
                io_path = f"/proc/{pid_dir}/io"

                if os.path.isfile(comm_path) and os.path.isfile(io_path):
                    try:
                        with open(comm_path, "r", encoding="utf-8") as cf:
                            comm = cf.read().strip()
                        if not comm:
                            continue

                        r_bytes = 0
                        w_bytes = 0
                        with open(io_path, "r", encoding="utf-8") as iof:
                            for line in iof:
                                if line.startswith("read_bytes:"):
                                    r_bytes = int(line.split()[1])
                                elif line.startswith("write_bytes:"):
                                    w_bytes = int(line.split()[1])

                        if comm not in aggregated:
                            aggregated[comm] = {
                                "name": comm,
                                "read_bytes": 0,
                                "write_bytes": 0,
                                "instances": 0,
                            }
                        aggregated[comm]["read_bytes"] += r_bytes
                        aggregated[comm]["write_bytes"] += w_bytes
                        aggregated[comm]["instances"] += 1
                    except Exception:
                        pass

            results = []
            for item in aggregated.values():
                tot = item["read_bytes"] + item["write_bytes"]
                if tot > 0:
                    results.append({
                        "name": item["name"],
                        "read_mb": round(item["read_bytes"] / (1024 * 1024), 1),
                        "write_mb": round(item["write_bytes"] / (1024 * 1024), 1),
                        "total_mb": round(tot / (1024 * 1024), 1),
                        "instances": item["instances"],
                    })
            results.sort(key=lambda x: x["total_mb"], reverse=True)
            return results[:3]
        except Exception:
            return []

    def read_psi_io(self) -> Dict[str, float]:
        """Parse Pressure Stall Information for I/O subsystem."""
        path = "/proc/pressure/io"
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

    def collect(self) -> Dict[str, Any]:
        """Collect snapshot of storage throughput, partition status, and disk consumers."""
        read_mb_s, write_mb_s = self.read_disk_throughput()
        self.sparkline_read.append(read_mb_s)
        self.sparkline_write.append(write_mb_s)

        partitions = self.read_partitions()
        top_disk_io = self.collect_top_disk_io()
        psi_io = self.read_psi_io()

        return {
            "read_mb_s": read_mb_s,
            "write_mb_s": write_mb_s,
            "sparkline_read": list(self.sparkline_read),
            "sparkline_write": list(self.sparkline_write),
            "partitions": partitions,
            "top_disk_io": top_disk_io,
            "psi_io": psi_io,
        }
