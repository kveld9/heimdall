# WatchCat - Zero-Jank KDE Plasma 6 System Monitor & Network Budget Plasmoid

WatchCat is a system monitor Plasmoid and lightweight telemetry daemon built specifically for KDE Plasma 6 on Wayland. It delivers an ultra-clean dark violet aesthetic with real-time hardware sparklines, daily network budget tracking, kernel Pressure Stall Information (PSI), ZRAM memory compression stats, and systemd service health.

---

## Key Features

- **Multi-Page Zero-Jank Dashboard**:
  - **Page 1: Network & Quota**: Live download/upload sparklines, large daily budget slider with tick marks, rolling 7-day breakdown table ("THIS WEEK - BY DAY"), "TODAY SPLIT" donut chart, and per-process network traffic list.
  - **Page 2: Compute & Memory**: CPU utilization with sparklines, physical RAM vs ZRAM compression ratio, memory saved in MB, and CPU/Memory kernel Pressure Stall Information (PSI).
  - **Page 3: Storage & Disk I/O**: Live disk read/write throughput sparklines, mounted filesystem capacities and usage bars, and I/O PSI.
  - **Page 4: Systemd Daemons & Health**: DBus-integrated NFailedUnits counter and failed services list, and hardware thermal sensors (/sys/class/hwmon).
- **Desktop Widget with Collapse/Expand**:
  - Compact capsule mode (530x44px) showing live summary metrics and an Expand button.
  - Full dashboard mode (720x560px) with the 4-page navigation stack and a Collapse button.
- **Unified Dark Violet Aesthetic**:
  - Deep obsidian-violet backgrounds (#120f1d, #1a162b), crisp violet borders (#3b305d), radiant violet highlights (#c084fc), and soft lavender accents (#e9d5ff).
- **Asynchronous Zero-Jank Daemon**:
  - Standalone Python daemon collecting kernel metrics without root privileges.
  - Serves instant snapshots over http://127.0.0.1:9871/api/telemetry so the Plasma Shell UI thread never blocks on disk or socket I/O.
  - Persistent 7-day circular buffer in ~/.local/share/watchcat/history.json.

---

## Quick Start & Installation

### 1. Install & Enable
Run the automated installation script:
```bash
./scripts/install.sh
```
This registers the Plasmoid with `kpackagetool6` and enables the background telemetry daemon as a `systemd --user` service.

### 2. Live Desktop Preview
To test or preview the widget in a standalone desktop window:
```bash
./scripts/run_preview.sh
```

### 3. Adding to your Desktop or Panel
1. Right-click on your KDE desktop or panel and select **Add Widgets...**
2. Search for **WatchCat** and drag it to your desired location.

### 4. Uninstall
```bash
./scripts/uninstall.sh
```

---

## Architecture & Data Sources

| Telemetry | Source | Privileges |
|---|---|---|
| Network Traffic & Interface Rates | /proc/net/dev, /proc/net/route | User |
| Sockets & Process Association | ss -tupi, /proc/<pid>/io | User |
| Daily Budget & Weekly History | ~/.local/share/watchcat/history.json | User |
| CPU & Utilization | /proc/stat delta | User |
| Memory & ZRAM Compression | /proc/meminfo, /sys/block/zram0/mm_stat | User |
| PSI (Pressure Stall Info) | /proc/pressure/{cpu,memory,io} | User |
| Disk I/O Rates | /proc/diskstats delta | User |
| Filesystems | os.statvfs on mounted paths | User |
| Systemd Status | org.freedesktop.systemd1 / systemctl | User |
| Thermal Sensors | /sys/class/hwmon/ | User |
