# AGENTS.md - Developer & Agent Guidelines for WatchCat

This document specifies architectural rules, coding standards, and strict operational invariants for any AI agent or human contributor working in this repository.

---

## 1. Absolute Rule: Strict Prohibition of Emojis

- **ZERO EMOJIS ALLOWED**: Under no circumstance shall any emoji be used anywhere in this repository.
- This prohibition applies strictly to:
  - Markdown documentation files (`README.md`, `AGENTS.md`, design notes, guides).
  - Code comments (Python, QML, Shell, C++).
  - User interface labels, strings, tooltips, and buttons.
  - Commit messages and Pull Request titles/descriptions.
  - Script output, logging statements, and console prints.
- Use clean ASCII indicators when necessary for status output (for example: `[+]`, `[-]`, `[*]`, `[!]`, `[v]`, `[x]`, `^`, `v`).

---

## 2. Project Architecture Overview

WatchCat consists of two decoupled components:

1. **Backend Telemetry Daemon (`daemon/`)**:
   - `daemon/watchcat_daemon.py`: Independent daemon collecting system metrics at 1-second intervals.
   - `daemon/storage.py`: Handles persistent storage for daily quota tracking and a rolling 7-day breakdown in `~/.local/share/watchcat/history.json`.
   - `daemon/service/watchcat.service`: Systemd user service unit running under `systemctl --user`.
   - Serves instantaneous, zero-overhead JSON snapshots via HTTP on `127.0.0.1:9871` (`/api/telemetry`, `/api/budget`, `/api/week`, `/health`).

2. **Frontend Plasmoid (`plasmoid/`)**:
   - Target environment: **KDE Plasma 6 (Wayland)** with Qt 6.11+ and KF6 Kirigami.
   - `plasmoid/metadata.json`: KPlugin metadata specifying `Plasma/Applet` and `X-Plasma-API-Minimum-Version: 6.0`.
   - `plasmoid/contents/ui/Theme.qml`: Single source of truth for colors and typographic scale.
   - `plasmoid/contents/ui/main.qml`: Root `PlasmoidItem` managing asynchronous polling, desktop sizing, and representation switching.
   - `plasmoid/contents/ui/FullRepresentation.qml`: 4-page dashboard container supporting both expanded view and compact floating capsule view on the desktop.

---

## 3. Telemetry & Zero-Jank Invariants

1. **Zero-Jank UI Thread Guarantee**:
   - QML must never perform blocking syscalls, subprocess executions (`QProcess`), synchronous file I/O, or network operations on the main rendering thread.
   - All metric collection and calculations must reside exclusively inside the Python daemon.
   - The QML client fetches telemetry asynchronously via `XMLHttpRequest` with short timeouts (900ms) or local event buses.

2. **Unprivileged Metric Collection**:
   - Do not require `root` or `sudo` privileges for any metric.
   - Network throughput: `/proc/net/dev` and `/proc/net/route`.
   - Per-process sockets: Unprivileged `ss -tupi` and `/proc/<pid>/io`.
   - Memory and compression: `/proc/meminfo` and `/sys/block/zram0/mm_stat`.
   - Pressure Stall Information: `/proc/pressure/{cpu,memory,io}`.
   - Disk I/O: `/proc/diskstats` and `os.statvfs`.
   - System health: `org.freedesktop.systemd1` and `/sys/class/hwmon/`.

---

## 4. Design & Theme System Standards

1. **Single Source of Truth**:
   - All colors and formatting helpers must be consumed from `Theme.qml`.
   - Never embed ad-hoc, hardcoded hex colors inside individual page components.

2. **Translucent Monochromatic WM Palette**:
   - Primary Background: `Qt.rgba(0.04, 0.04, 0.05, 0.70)` (Smoked translucent glass)
   - Card Background: `Qt.rgba(1.0, 1.0, 1.0, 0.04)` (Frosted translucent surface)
   - Card Highlight: `Qt.rgba(1.0, 1.0, 1.0, 0.08)` (Hover and elevated glass)
   - Input/Rail Inset: `Qt.rgba(0.0, 0.0, 0.0, 0.45)`
   - Borders: `Qt.rgba(1.0, 1.0, 1.0, 0.12)` (Crisp translucent border), `Qt.rgba(1.0, 1.0, 1.0, 0.06)` (Subtle divider)
   - Accent White: `#ffffff` (Primary highlights, upload speed, budget knob, active tabs)
   - Accent Silver / Grey: `#9ca3af` (Secondary highlights, download speed, pill badges)
   - Accent Dark Slate: `#374151` (Doughnut secondary arc, capacity track)
   - Text Primary: `#ffffff` (High-contrast pure white)
   - Text Secondary: `#9ca3af` (Clean readable silver-grey)
   - Text Muted: `#52525b` (Dimmed atmospheric grey)
   - Background Hints: `PlasmaCore.Types.NoBackground` to eliminate opaque system frames and let rounded translucent glass reach the edges cleanly.

3. **Desktop Widget Resizing & Collapsing**:
   - The Plasmoid must handle desktop placement (`Planar` form factor) gracefully.
   - When collapsed: Compact floating capsule (~530x44px).
   - When expanded: Complete 4-page dashboard (720x560px).
   - `implicitWidth` and `implicitHeight` in `main.qml` must track the `isCollapsed` state to prevent empty layout borders on the desktop.

---

## 5. Deployment, Packaging & Verification

1. **Scripts Directory (`scripts/`)**:
   - `scripts/install.sh`: Packages and updates the plasmoid via `kpackagetool6`, sets up and restarts the systemd user service.
   - `scripts/run_preview.sh`: Starts the daemon and runs `plasmawindowed org.kde.plasma.watchcat` for instant windowed testing.
   - `scripts/uninstall.sh`: Completely removes the applet and disables the systemd service.

2. **Verification Checklist Before Committing**:
   - Syntax check daemon scripts: `python3 -m py_compile daemon/*.py`.
   - Test daemon telemetry snapshot: `curl -s http://127.0.0.1:9871/api/telemetry | jq .`.
   - Upgrade package: `./scripts/install.sh`.
   - Test QML rendering without errors: `timeout 4 plasmawindowed org.kde.plasma.watchcat`.
   - Check for forbidden emojis: verify zero matches in modified files.

---

## 6. Git & Commit Guidelines

- Format: Conventional Commits in English (`feat:`, `fix:`, `style:`, `refactor:`, `docs:`, `perf:`).
- No emojis in commit messages.
- No `Co-Authored-By` or AI attribution trailers.
