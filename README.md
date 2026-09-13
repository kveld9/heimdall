# Heimdall - Zero-Jank KDE Plasma 6 System Telemetry & Monitor Plasmoid

Heimdall is an aesthetic system telemetry Plasmoid and unprivileged background monitoring daemon built specifically for KDE Plasma 6 on Wayland. Inspired by the vigilant guardian of Norse mythology, Heimdall monitors kernel Pressure Stall Information (PSI), ZRAM memory compression, network budgets, disk I/O, scheduled systemd timers, and hardware thermals with zero compositor jank.

---

## Key Features

- **Multi-Page Zero-Jank Dashboard**:
  - **Page 1: Network & Quota**: Live download/upload sparklines, large daily budget slider with tick marks and remaining quota, rolling 7-day breakdown table ("THIS WEEK - BY DAY"), "TODAY SPLIT" donut chart, and per-process network traffic list grouped by command name.
  - **Page 2: Compute & Memory**: Full-width CPU sparkline, physical RAM utilization vs ZRAM compression ratio, memory saved in MB, ZRAM device capacity allocation bar, and Top 3 CPU and Top 3 RAM processes.
  - **Page 3: Storage & Disk I/O**: Live disk read/write throughput sparklines, deduplicated physical filesystem pools (`Root & Home (/)` and `/boot`), Top 3 disk consumers, and kernel I/O PSI status indicator (`OPTIMAL`, `ELEVATED`, `STALLED`).
  - **Page 4: Systemd Daemons & Vitals**: Host uptime, 1m/5m/15m load average, kernel OOM terminations, systemd service health, upcoming scheduled timers (`systemctl list-timers`), and a compact hardware thermal grid (/sys/class/hwmon).
- **Desktop Widget with Collapse/Expand**:
  - Compact capsule mode (520x52px) showing live summary metrics and an Expand button.
  - Full dashboard mode (720x560px) with 4-page navigation stack and a Collapse button.
- **Translucent Monochromatic WM Aesthetic**:
  - Smoked translucent glass (`rgba(0.04, 0.04, 0.05, 0.70)`), frosted cards, delicate translucent borders, high-contrast white typography, and silver-grey metrics.
- **Modular Asynchronous Daemon**:
  - Standalone Python daemon collecting kernel metrics without root privileges.
  - Serves instantaneous JSON snapshots over `http://127.0.0.1:9871/api/telemetry` so the Plasma render thread never blocks.
  - Persistent 30-day circular buffer in `~/.local/share/heimdall/history.json`.

---

## Quick Start & Installation

### 1. Install & Enable
Run the automated installation script:
```bash
./scripts/install.sh
```
This registers the Plasmoid with `kpackagetool6` and enables the background telemetry daemon as a `systemd --user` service (`heimdall.service`).

### 2. Live Desktop Preview
To test or preview the widget in a standalone desktop window:
```bash
./scripts/run_preview.sh
```

### 3. Adding to your Desktop or Panel
1. Right-click on your KDE desktop or panel and select **Add Widgets...**
2. Search for **Heimdall** and drag it to your desired location.

### 4. Verification Pipeline
```bash
./scripts/verify.sh
```

### 5. Uninstall
```bash
./scripts/uninstall.sh
```

---

## Architecture & Data Sources

| Telemetry | Source | Privileges |
|---|---|---|
| Network Traffic & Interface Rates | /proc/net/dev, /proc/net/route | User |
| Sockets & Process Association | ss -tupi, /proc/<pid>/io | User |
| Daily Budget & Weekly History | ~/.local/share/heimdall/history.json | User |
| CPU & Utilization | /proc/stat delta | User |
| Memory & ZRAM Compression | /proc/meminfo, /sys/block/zram0/{mm_stat,disksize} | User |
| PSI (Pressure Stall Info) | /proc/pressure/{cpu,memory,io} | User |
| Disk I/O Rates | /proc/diskstats delta | User |
| Filesystems (Deduplicated) | os.statvfs and os.stat(mount).st_dev | User |
| Systemd Status & Timers | systemctl --failed, systemctl list-timers | User |
| System Vitals & OOM Kills | /proc/uptime, /proc/loadavg, /proc/vmstat | User |
| Thermal Sensors | /sys/class/hwmon/ | User |
