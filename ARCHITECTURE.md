# WatchCat Technical Architecture & Design Rationale

This document provides a comprehensive technical breakdown of WatchCat. It documents the exact mechanisms of every subsystem, the data pipeline from kernel to display, and the specific rationale behind each architectural and stylistic decision.

---

## 1. System Architecture Overview

WatchCat is partitioned into two decoupled tiers:

1. **Telemetry & Persistence Daemon (`daemon/`)**:
   An independent background process operating entirely in user space. It samples kernel interfaces, calculates rolling rates, manages daily budget limits, and exposes zero-overhead JSON snapshots over local HTTP (`127.0.0.1:9871`).
2. **Frontend Plasmoid (`plasmoid/`)**:
   A native KDE Plasma 6 applet written in declarative QML (Qt 6.11 / KF6). It runs asynchronously, fetching telemetry snapshots at 1-second intervals without performing blocking system calls on the compositor thread.

```
+-------------------------------------------------------------------------+
|                              Linux Kernel                               |
|  /proc/net/dev   ss -tupi   /proc/stat   /proc/pressure   /sys/hwmon   |
+------------------------------------+------------------------------------+
                                     | (Unprivileged 1 Hz polling)
                                     v
+------------------------------------+------------------------------------+
|                   WatchCat Telemetry Daemon                             |
|  - Engine: Calculates deltas, CPU/IO rates, per-process socket maps     |
|  - Storage: Circular buffer, daily quota (~/.local/share/watchcat)      |
|  - Server: Threading HTTP server on 127.0.0.1:9871                      |
+------------------------------------+------------------------------------+
                                     | (Async XMLHttpRequest / JSON)
                                     v
+------------------------------------+------------------------------------+
|                   Frontend Plasmoid (Plasma 6)                          |
|  - main.qml: Zero-Jank polling loop & dynamic desktop sizing            |
|  - Theme.qml: Translucent monochrome WM color tokens                    |
|  - FullRepresentation.qml: 4-page dashboard or compact capsule          |
+-------------------------------------------------------------------------+
```

---

## 2. Telemetry Engine & Kernel Interfaces

Every metric is collected without requiring root (`sudo`) privileges:

### 2.1 Network Rates & Default Route
- **Sources**: `/proc/net/dev` and `/proc/net/route`.
- **Mechanism**:
  1. `/proc/net/route` is scanned for destination `00000000` to dynamically identify the active default gateway interface (e.g. `enp7s0` or `wlp2s0`). If inactive, it falls back to the first up interface in `/sys/class/net/`.
  2. `/proc/net/dev` provides cumulative hardware counters: `rx_bytes` (field 0) and `tx_bytes` (field 8).
  3. The engine computes `(current_bytes - previous_bytes) / delta_time` to yield instantaneous speeds (`down_rate_bps`, `up_rate_bps`).
- **Rationale**: Direct `/proc/net/dev` reading avoids subprocess overhead and provides sub-millisecond hardware counter accuracy with zero CPU cost.

### 2.2 Sockets and Process Association
- **Sources**: `ss -tupi` and `/proc/<pid>/io`.
- **Mechanism**:
  1. `ss -tupi` is invoked with a 800ms timeout to retrieve established TCP/UDP sockets owned by the user.
  2. The parser isolates process names and PIDs from the `users:(("name",pid=X,fd=Y))` token.
  3. `/proc/<pid>/io` reads `read_bytes` and `write_bytes` to calculate per-process I/O deltas, sorting processes by combined throughput.
- **Rationale**: Kernel eBPF/kprobes requires `CAP_BPF` or root. Standard `ss -tupi` paired with user `/proc/<pid>/io` allows unprivileged users to identify top data-consuming applications reliably.

### 2.3 Compute, ZRAM & Memory
- **Sources**: `/proc/stat`, `/proc/meminfo`, and `/sys/block/zram0/mm_stat`.
- **Mechanism**:
  1. **CPU**: Reads the first `cpu` line from `/proc/stat`. Computes non-idle vs idle tick deltas: `cpu_pct = (1.0 - delta_idle / delta_total) * 100.0`.
  2. **RAM**: Extracts `MemTotal` and `MemAvailable` from `/proc/meminfo` to calculate actual allocated memory excluding kernel page cache.
  3. **ZRAM Compression**: Reads `/sys/block/zram0/mm_stat`.
     - Token 0: `orig_data_size` (uncompressed size in bytes).
     - Token 1: `compr_data_size` (compressed size stored in RAM).
     - Token 2: `mem_used_total` (total memory consumed including allocator overhead).
     - Calculates compression ratio (`orig / compr`) and memory saved in MB.
- **Rationale**: Directly parsing `/sys/block/zram0/mm_stat` provides real-time visibility into the memory compression efficiency of zram-generator or CachyOS/Arch default swap without extra packages.

### 2.4 Pressure Stall Information (PSI)
- **Sources**: `/proc/pressure/cpu`, `/proc/pressure/memory`, `/proc/pressure/io`.
- **Mechanism**: Parses 10-second, 60-second, and 300-second averages for `some` (tasks stalled on resource) and `full` (all runnable tasks stalled).
- **Rationale**: Traditional load average is ambiguous because it conflates CPU runnable count with uninterruptible disk sleep. PSI gives mathematically rigorous detection of hardware resource starvation.

### 2.5 Disk I/O & Mounted Partitions
- **Sources**: `/proc/diskstats` and `os.statvfs`.
- **Mechanism**:
  1. `/proc/diskstats` tracks cumulative sectors read and written for primary block devices (`nvme0n1`, `sda`). Multiplied by 512 bytes and divided by delta time to determine MB/s throughput.
  2. `os.statvfs` inspects `/` and `/home` to track total, used, and free capacity.
- **Rationale**: Eliminates parsing `df` or spawning `iostat`.

### 2.6 Systemd Health & Sensors
- **Sources**: `systemctl is-system-running`, `systemctl --failed`, and `/sys/class/hwmon/*/temp*_input`.
- **Mechanism**: Queries system failure states (`NFailedUnits`) and thermal millidegrees Celsius from `/sys/class/hwmon`.
- **Rationale**: Avoids heavy DBus client libraries by consuming standard kernel sysfs nodes and systemctl user commands.

---

## 3. Storage & Persistence Architecture

### 3.1 Design Decisions
- **Path**: `~/.local/share/watchcat/history.json` and `config.json`.
- **Format**: Structured JSON with a 30-day automatic retention pruning.
- **Why not SQLite?**:
  WatchCat requires appending simple daily byte increments once per second and retrieving a 7-day chronological slice for display. A structured JSON document eliminates binary database dependencies, prevents database lock contention, and allows transparent user inspection and backups.
- **Quota Accounting**:
  Network card hardware counters reset on reboot. The storage engine tracks *deltas* between consecutive samples (`current_rx - prev_rx`) and accumulates them into the persistent daily record. When the system restarts, historical daily accumulation is preserved intact.

---

## 4. Frontend Plasmoid Design & Aesthetics

### 4.1 Zero-Jank Guarantee
- The QML UI never performs blocking synchronous file reads (`QFile`), system commands (`QProcess`), or heavy parsing on the render thread.
- `main.qml` runs an asynchronous `Timer` at 1000ms invoking `XMLHttpRequest` with a 900ms timeout against `127.0.0.1:9871`.
- If the daemon is temporarily unavailable, the UI gracefully renders cached values or zeroed indicators without freezing plasmashell.

### 4.2 Window Manager (WM) Translucent Monochromatic Aesthetic
- **Rationale**:
  The user desktop features a minimalist, dark monochromatic wallpaper (fog and night streetlights). Generic colored widgets (olive, bright green, violet) visually clash with clean desktop rices.
- **Key Visual Elements**:
  1. **Frameless rounded glass**:
     `Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground` strips Plasma's default opaque rectangular border. The widget reaches directly to its own rounded boundaries (`radius: 16` for expanded, `radius: 22` for capsule).
  2. **Smoked Translucent Glass (`bgPrimary`)**:
     `Qt.rgba(0.04, 0.04, 0.05, 0.70)` lets the desktop wallpaper softly show through with 70% opacity.
  3. **Frosted Glass Cards (`bgCard`)**:
     `Qt.rgba(1.0, 1.0, 1.0, 0.04)` creates elevated surfaces with delicate translucent borders (`Qt.rgba(1.0, 1.0, 1.0, 0.12)`).
  4. **High-Contrast Monochromatic Accents**:
     - Primary white (`#ffffff`): upload rates, budget knob, active tabs, sparkline primary stroke.
     - Metallic silver (`#9ca3af`): download rates, secondary metric labels.
     - Dark slate (`#374151`): doughnut chart secondary segment.
  5. **Desktop Placement & Dynamic Sizing**:
     - Collapsed Capsule: `530x44px` pill with real-time status and an `[v] Expandir` button.
     - Expanded Dashboard: `720x560px` 4-page stack with an `[^] Contraer` button.
     - `implicitWidth` and `implicitHeight` in `main.qml` update dynamically to resize the Plasma desktop container cleanly.

---

## 5. Deployment & System Integration

1. **Packaging**:
   - `scripts/install.sh`: Invokes `kpackagetool6 -t Plasma/Applet -u plasmoid` (or `-i`), links `~/.local/share/plasma/plasmoids/org.kde.plasma.watchcat`, and writes `~/.config/systemd/user/watchcat.service`.
2. **Preview & Testing**:
   - `scripts/run_preview.sh`: Ensures daemon is running and invokes `plasmawindowed org.kde.plasma.watchcat` for isolated desktop verification.
3. **Uninstallation**:
   - `scripts/uninstall.sh`: Disables the user service, deletes unit files, and deregisters package from `kpackagetool6`.

---

## 6. Maintenance & Documentation Protocol

Whenever any code in `daemon/`, `plasmoid/`, or `scripts/` is modified:
1. Update this document (`ARCHITECTURE.md`) to document the changed component, metric source, or UI structure.
2. Verify that the strict zero-emoji policy is maintained.
3. Run `python3 -m py_compile daemon/*.py` and test QML rendering with `plasmawindowed`.
