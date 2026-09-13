# Heimdall Technical Architecture & Design Rationale

This document provides a comprehensive technical breakdown of Heimdall. It documents the exact mechanisms of every subsystem, the data pipeline from kernel to display, and the specific rationale behind each architectural and stylistic decision.

---

## 1. System Architecture Overview

Heimdall is partitioned into two decoupled tiers:

1. **Telemetry & Persistence Daemon (`daemon/`)**:
   An independent background process operating entirely in user space. It samples kernel interfaces, calculates rolling rates, manages daily budget limits, groups multi-instance processes, tracks systemd timers, and exposes zero-overhead JSON snapshots over local HTTP (`127.0.0.1:9871`).
2. **Frontend Plasmoid (`plasmoid/`)**:
   A native KDE Plasma 6 applet written in declarative QML (Qt 6.11 / KF6). It runs asynchronously, fetching telemetry snapshots at 1-second intervals without performing blocking system calls on the compositor thread.

```
+-------------------------------------------------------------------------+
|                              Linux Kernel                               |
|  /proc/net/dev   /proc/stat   /proc/pressure   /sys/hwmon   /proc/vmstat|
|  /sys/block/zram0   /proc/uptime   /proc/loadavg   /proc/<pid>/io       |
+------------------------------------+------------------------------------+
                                     | (Unprivileged 1 Hz polling)
                                     v
+------------------------------------+------------------------------------+
|                   Heimdall Telemetry Daemon                             |
|  - Engine: Calculates deltas, CPU/IO rates, per-comm process aggregator |
|  - Systemd: Queries failed units, list-timers JSON, uptime, loadavg     |
|  - Storage: Circular buffer, daily quota (~/.local/share/heimdall)      |
|  - Server: Threading HTTP server on 127.0.0.1:9871                      |
+------------------------------------+------------------------------------+
                                     | (Async XMLHttpRequest / JSON)
                                     v
+------------------------------------+------------------------------------+
|                   Frontend Plasmoid (Plasma 6)                          |
|  - main.qml: Zero-Jank polling loop & dynamic desktop sizing            |
|  - Theme.qml: Translucent monochrome WM color tokens & typography       |
|  - FullRepresentation.qml: 4-page dashboard or compact capsule          |
|  - NetworkPage: Daily traffic overview, aligned week table, split donut  |
|  - ComputePage: Full-width CPU sparkline, ZRAM capacity, Top CPU/RAM    |
|  - StoragePage: Dual read/write sparklines, mounts, Top Disk, PSI badge |
|  - SystemdPage: System vitals, service state, timers, thermal grid      |
+-------------------------------------------------------------------------+
```

---

## 2. Telemetry Engine & Kernel Interfaces

Every metric is collected without requiring root (`sudo`) privileges:

### 2.1 Network Rates & Default Route
- **Sources**: `/proc/net/dev` and `/proc/net/route`.
- **Mechanism**:
  1. `/proc/net/route` is scanned for destination `00000000` to dynamically identify the active default gateway interface (e.g. `enp7s0` or `wlp2s0`). If inactive, it falls back to the first active interface in `/sys/class/net/`.
  2. `/proc/net/dev` provides cumulative hardware counters: `rx_bytes` (field 0) and `tx_bytes` (field 8).
  3. The engine computes `(current_bytes - previous_bytes) / delta_time` to yield instantaneous speeds (`down_rate_bps`, `up_rate_bps`).
- **Rationale**: Direct `/proc/net/dev` reading avoids subprocess overhead and provides sub-millisecond hardware counter accuracy with zero CPU cost.

### 2.2 Sockets and Process Grouping by Binary Comm
- **Sources**: `ss -tupi` and `/proc/<pid>/io`.
- **Mechanism**:
  1. `ss -tupi` is invoked with an 800ms timeout to retrieve established TCP/UDP sockets owned by the user.
  2. The parser isolates process names and PIDs from the `users:(("name",pid=X,fd=Y))` token.
  3. Rather than displaying separate entries for every thread or worker child (such as multiple instances of web browsers or IDE language servers), processes are aggregated by base binary name (`comm`).
  4. For each distinct binary, the daemon sums socket activity, read/write I/O deltas, and counts the number of running instances (`instances: N`).
- **Rationale**: Listing individual thread PIDs clutters the UI with duplicate names. Grouping by base command gives an accurate, human-readable overview of which application is consuming network bandwidth.

### 2.3 Compute, ZRAM Capacity & Top Process Consumers
- **Sources**: `/proc/stat`, `/proc/meminfo`, `/sys/block/zram0/{mm_stat,disksize}`, and `ps -eo comm,%cpu,%mem,rss`.
- **Mechanism**:
  1. **CPU Utilization**: Reads the first `cpu` line from `/proc/stat`. Computes non-idle vs idle tick deltas: `cpu_pct = (1.0 - delta_idle / delta_total) * 100.0`.
  2. **Physical RAM**: Extracts `MemTotal` and `MemAvailable` from `/proc/meminfo` to calculate actual allocated memory excluding kernel page cache.
  3. **ZRAM Compression & Capacity**: Reads `/sys/block/zram0/mm_stat` and `/sys/block/zram0/disksize`.
     - `disksize`: Device pool capacity (e.g. 29.2 GB allocated).
     - `orig_data_size`: Uncompressed data size in bytes.
     - `compr_data_size`: Compressed bytes currently stored in RAM.
     - `mem_used_total`: Total memory consumed including allocator overhead.
     - `usage_pct`: Percentage of total allocated ZRAM pool capacity in use (`(compr_data_size / disksize) * 100`).
     - Calculates compression ratio (`orig / compr`) and memory saved in MB.
  4. **Top CPU and Memory Consumers**: Executes `ps -eo comm,%cpu,%mem,rss --no-headers --sort=-%cpu` to extract active processes. Aggregates multi-instance binaries by name and extracts the top 3 processes by `%CPU` and top 3 processes by `RSS` memory.
- **Rationale**: Displays real CPU and memory hogs directly inside the Compute panel without leaving dead space. Showing ZRAM compressed size against its allocated pool capacity provides clear context on remaining swap headroom.

### 2.4 Pressure Stall Information (PSI)
- **Sources**: `/proc/pressure/cpu`, `/proc/pressure/memory`, `/proc/pressure/io`.
- **Mechanism**: Parses 10-second, 60-second, and 300-second averages for `some` (tasks stalled on resource) and `full` (all runnable tasks stalled).
- **Rationale**: Traditional load average is ambiguous because it conflates CPU runnable count with uninterruptible disk sleep. PSI gives mathematically rigorous detection of hardware resource starvation.

### 2.5 Disk I/O, Mount Deduplication & Top Disk Consumers
- **Sources**: `/proc/diskstats`, `os.statvfs`, and `/proc/<pid>/io`.
- **Mechanism**:
  1. `/proc/diskstats` tracks cumulative sectors read and written for primary block devices (`nvme0n1`, `sda`). Multiplied by 512 bytes and divided by delta time to determine MB/s throughput.
  2. **Mount Deduplication & Filtering**: When `/` and `/home` share the same physical filesystem partition (e.g. Btrfs subvolumes or unified root), checking `os.stat(mount).st_dev` detects identical device numbers and merges them into a single entry (`Root & Home (/)`). Boot partitions under 5 GB (such as `/boot` and `/boot/efi`) are intentionally pruned to eliminate clutter and prioritize active user storage pools (`/`, `/home`, `/mnt/*`, `/media/*`).
  3. **Top Lifetime Disk I/O Consumers**: Samples `/proc/<pid>/io` across running user processes, aggregates by binary name, and presents the top 3 disk consumers labeled explicitly as cumulative lifetime read and write I/O.
  4. **PSI Status Formatter**: Evaluates `psi_io` averages to classify disk pipeline status into `OPTIMAL`, `ELEVATED`, or `STALLED`.
- **Rationale**: Eliminates non-actionable boot partition bars and gives clear distinction between instantaneous throughput and lifetime process I/O.

### 2.6 Systemd Health, Timers, Vitals & Thermals
- **Sources**: `systemctl is-system-running`, `systemctl --failed`, `systemctl list-timers --output=json`, `/proc/uptime`, `/proc/loadavg`, `os.cpu_count()`, `/proc/vmstat`, and `/sys/class/hwmon/*/temp*_input`.
- **Mechanism**:
  1. **Systemd Services**: Queries `systemctl --failed` for broken units and exposes failed unit counts and names.
  2. **Scheduled Timers with Microsecond Countdown**:
     In systemd's JSON output, the `next` attribute represents a 64-bit microsecond UNIX timestamp (`next_us`). The daemon dynamically calculates the exact countdown via `diff_sec = (next_us / 1_000_000.0) - time.time()`, formatted into a compact countdown string (`_format_countdown`: e.g. `4h 46m`, `21h 45m`, `1d 4h`). A legendless plain-text parser serves as a robust fallback.
  3. **System Vitals & CPU Thread Context**:
     - Host uptime parsed from `/proc/uptime`.
     - 1m, 5m, 15m load averages parsed from `/proc/loadavg`.
     - `os.cpu_count()` provides the authoritative logical thread count (e.g. 16 threads). This enables the frontend to render an intuitive capacity ratio (`(load1m / cpu_cores) * 100`) and color-coded threshold gauge.
     - Recent OOM terminations counted from `oom_kill` in `/proc/vmstat`.
  4. **Thermals**: Reads temperature millidegrees Celsius from `/sys/class/hwmon` and formats them into a compact grid with warnings at >= 65 °C (warm) and >= 80 °C (critical).
- **Rationale**: Solves false-negative timer readings caused by timestamp type mismatch and contextualizes raw load averages against actual logical core capacity.

---

## 3. Storage & Persistence Architecture

### 3.1 Design Decisions
- **Path**: `~/.local/share/heimdall/history.json` and `config.json`.
- **Format**: Structured JSON with 30-day automatic retention pruning.
- **Why not SQLite?**:
  Heimdall requires appending simple daily byte increments once per second and retrieving a 7-day chronological slice for display. A structured JSON document eliminates binary database dependencies, prevents database lock contention, and allows transparent user inspection and backups.
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
  The user desktop features a minimalist, dark monochromatic wallpaper. Generic bright colored themes clash with clean desktop rices.
- **Key Visual Elements**:
  1. **Frameless rounded glass**:
     `Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground` strips Plasma's default opaque rectangular border. The widget reaches directly to its own rounded boundaries (`radius: 16` for expanded, `radius: 22` for capsule).
  2. **Smoked Translucent Glass (`bgPrimary`)**:
     `Qt.rgba(0.04, 0.04, 0.05, 0.70)` lets the desktop wallpaper softly show through with 70% opacity.
  3. **Frosted Glass Cards (`bgCard`)**:
     `Qt.rgba(1.0, 1.0, 1.0, 0.04)` creates elevated surfaces with delicate translucent borders (`Qt.rgba(1.0, 1.0, 1.0, 0.12)`).
  4. **High-Contrast Monochromatic Typography & Functional Accents**:
     - Primary text (`#ffffff`): high-contrast labels and headings.
     - Secondary text (`#d1d5db`): clear, readable silver-grey metrics.
     - Text Muted (`#9ca3af`): subheadings and auxiliary units with strong contrast against dark glass.
     - Monochromatic baseline: crisp white tracks and frosted elevated glass (`Qt.rgba(1.0, 1.0, 1.0, 0.16)`). Strict repository invariant prohibits chromatic drift; any user request to introduce arbitrary colors requires mandatory secondary confirmation. Hardware thermal levels and PSI stalls retain subdued functional alerts only where strictly necessary.
  5. **Desktop Placement & Dynamic Sizing**:
     - Collapsed Capsule: `520x52px` pill with real-time status and a `[v] Expandir` button. The visual card constrains its own width, height, and border-radius (`radius: 26`) while keeping the outer canvas transparent, eliminating any dark background container bloat on the desktop. The inner row is padded with 18px horizontal margins and dynamic button sizing to ensure zero text clipping or edge overflow.
     - Expanded Dashboard: `720x560px` 4-page stack with an `[^] Contraer` button.
     - Symmetrical Transitions: `main.qml` and `FullRepresentation.qml` animate `width`, `height`, and `radius` with `Easing.OutCubic` (250ms). Visual card avoids anchor overrides (`anchors.fill`) by maintaining persistent center alignment (`anchors.centerIn: parent`), allowing properties to drive identical fluid transitions on both expansion and contraction. Capsule and dashboard views smoothly cross-fade via opacity transitions.

### 4.3 Modular UI Component Library
Recurring visual patterns are encapsulated into reusable components under `plasmoid/contents/ui/components/`:
- `ProcessRow.qml`: Standardized process ranking row with fixed tabular column alignment. Process name and instance pill (`xN`) expand flexibly on the left, while secondary metrics (`detailText`, width: 70px) and highlight badges (`badge`, width: 64px) are rigidly right-anchored (`rightMargin: 16`) for terminal-grade tabular precision.
- `StatusBadge.qml`: Status pill with an indicator dot, high-contrast title, and muted explanatory description (used for PSI bottlenecks and system health).
- `MetricCard.qml`: Frosted glass container with translucent borders, uppercase header label, and slot for auxiliary controls.
- `Sparkline.qml`: Zero-jank Canvas renderer drawing continuous 30-to-60 point telemetry histories with pre-filled baseline buffers and translucent filled gradients.
- `BudgetSlider.qml`: Daily network traffic overview component. Visualizes total daily bytes transferred with a proportional dual-segment download vs. upload track, eliminating artificial quota caps and over-budget warnings for home Ethernet/broadband workflows.
- `DonutChart.qml`: Split circular arc visualization for download versus upload ratios.
- Weekly History Table (`NetworkPage.qml`): Implements rigid column width properties (`colDayWidth: 70`, `colDateWidth: 50`, `colDownWidth: 75`, `colUpWidth: 75`, `colTotalWidth: 100`) with anchor-based alignment across both header and delegates, guaranteeing terminal-grade tabular alignment across all resolutions.
- Top Network Applications: Horizontal scrollable strip with `Flickable.HorizontalFlick`, 16px escape margin footer, and mouse wheel propagation to prevent boundary collisions on desktop.
- Header System Synchronization (`Header.qml`): Real-time 1-second system timer dynamically rendering local date (`ddd, d MMM`) and time (`hh:mm`) without static fallbacks.
- Systemd Timers (`SystemdPage.qml`): Multi-line timer items with separated bullet indicators (`• `), expanded 4px vertical interline spacing, and 68px fixed-width right-anchored countdown badges.

---

## 5. Modular Backend Package Structure

The daemon is organized as an extensible Python package under `daemon/heimdall/`:

```
daemon/
|-- storage.py                       # Backward-compatibility shim
|-- heimdall_daemon.py               # Primary CLI execution entrypoint
|-- watchcat_daemon.py               # Backward-compatibility execution shim
\-- heimdall/
    |-- __init__.py                  # Package metadata
    |-- main.py                      # Orchestrator, CLI flags, signal handling
    |-- server.py                    # Threaded HTTP server and endpoint routing
    |-- storage.py                   # Quota tracking & 30-day circular persistence
    \-- collectors/
        |-- __init__.py              # Collectors registry
        |-- base.py                  # BaseCollector abstract interface contract
        |-- network.py               # Rates, routes, per-comm socket grouping
        |-- compute.py               # CPU, RAM, ZRAM capacity, top compute
        |-- storage.py               # Block I/O, device deduplication, disk PSI
        \-- health.py                # Systemd units, timers, vitals, thermals
```

### 5.1 Collector Interface Contract
Every telemetry provider inherits from `BaseCollector` and implements:
```python
class BaseCollector(abc.ABC):
    @abc.abstractmethod
    def collect(self) -> Dict[str, Any]:
        """Collect and return metrics snapshot as a JSON-serializable dictionary."""
        raise NotImplementedError
```
This guarantees strict isolation: adding a new sensor or subsystem never alters existing collectors or HTTP routing logic.

---

## 6. Automated Verification Pipeline

All quality gates are enforced automatically by `scripts/verify.sh`:
```bash
./scripts/verify.sh
```

The pipeline executes 4 verification phases in sub-second execution:
1. **Compilation Gate**: Validates all Python modules with `python3 -m py_compile`.
2. **Collector Smoke Test**: Instantiates all 4 collectors and asserts valid dictionaries and required keys.
3. **Zero-Emoji Audit**: Scans all Python, QML, Shell, and Markdown files with strict Unicode regex to verify zero emojis.
4. **Plasmoid Packaging Gate**: Validates `metadata.json` against Plasma 6 specifications.

---

## 7. Deployment & System Integration

1. **Packaging & Backward Compatibility**:
   - `scripts/install.sh`: Invokes `kpackagetool6 -t Plasma/Applet -u plasmoid` (or `-i`), links `~/.local/share/plasma/plasmoids/org.kde.plasma.heimdall`, and writes `~/.config/systemd/user/heimdall.service`.
   - **Legacy Compatibility Wrapper**: To prevent existing desktop and panel placements of `org.kde.plasma.watchcat` from displaying "package does not exist" errors, `install.sh` maintains a synchronous compatibility package under `~/.local/share/plasma/plasmoids/org.kde.plasma.watchcat` with its own `metadata.json` and a full copy of the `contents/` tree (as KPackage security restrictions in KDE Plasma 6 prohibit symlinks pointing outside the package root).
2. **Preview & Testing**:
   - `scripts/run_preview.sh`: Ensures daemon is running and invokes `plasmawindowed org.kde.plasma.heimdall` for isolated desktop verification.
3. **Uninstallation**:
   - `scripts/uninstall.sh`: Disables the user service, deletes unit files, and deregisters package from `kpackagetool6`.
