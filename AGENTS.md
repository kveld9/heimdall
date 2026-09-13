# AGENTS.md - Developer & Agent Guidelines for Heimdall

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

## 2. Absolute Rule: Strict English-Only Invariant across Repository

- **100% STRICT ENGLISH ACROSS THE ENTIRE REPOSITORY**: Under no circumstance shall any language other than English be used anywhere in this repository.
- This invariant applies unconditionally to:
  - All source code, backend daemon logic, QML components, shell scripts, and systemd units.
  - User interface labels, strings, buttons, tooltips, dialogs, badges, and status indicators (e.g. `Expand`, `Collapse`, `Today`, `Network`, `Compute`, `Storage`, `Daemons`).
  - Code comments, docstrings, variable/function identifiers, and logging statements.
  - All technical documentation (`README.md`, `ARCHITECTURE.md`, `AGENTS.md`, design notes, and guides).
  - Commit messages, Pull Request titles, descriptions, and git tags.
- No Spanish or any other natural language is permitted in any repository artifact or system code.

---

## 3. Project Architecture Overview

Heimdall consists of two decoupled components:

1. **Backend Telemetry Daemon (`daemon/`)**:
   - `daemon/heimdall_daemon.py`: Independent daemon collecting system metrics at 1-second intervals.
   - `daemon/heimdall/storage.py`: Handles persistent storage for daily quota tracking and a rolling 30-day breakdown in `~/.local/share/heimdall/history.json`.
   - `daemon/service/heimdall.service`: Systemd user service unit running under `systemctl --user`.
   - Serves instantaneous, zero-overhead JSON snapshots via HTTP on `127.0.0.1:9871` (`/api/telemetry`, `/api/budget`, `/api/week`, `/health`).

2. **Frontend Plasmoid (`plasmoid/`)**:
   - Target environment: **KDE Plasma 6 (Wayland)** with Qt 6.11+ and KF6 Kirigami.
   - `plasmoid/metadata.json`: KPlugin metadata specifying `Plasma/Applet` and `X-Plasma-API-Minimum-Version: 6.0`.
   - `plasmoid/contents/ui/Theme.qml`: Single source of truth for colors and typographic scale.
   - `plasmoid/contents/ui/main.qml`: Root `PlasmoidItem` managing asynchronous polling, desktop sizing, and representation switching.
   - `plasmoid/contents/ui/FullRepresentation.qml`: 4-page dashboard container supporting both expanded view and compact floating capsule view on the desktop.

---

## 4. Telemetry & Zero-Jank Invariants

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

## 5. Design & Theme System Standards

1. **Single Source of Truth**:
   - All colors and formatting helpers must be consumed from `Theme.qml`.
   - Never embed ad-hoc, hardcoded hex colors inside individual page components.

2. **Translucent Monochromatic WM Palette**:
   - Primary Background: `Qt.rgba(0.04, 0.04, 0.05, 0.70)` (Smoked translucent glass)
   - Card Background: `Qt.rgba(1.0, 1.0, 1.0, 0.04)` (Frosted translucent surface)
   - Card Highlight: `Qt.rgba(1.0, 1.0, 1.0, 0.08)` (Hover and elevated glass)
   - Input/Rail Inset: `Qt.rgba(0.0, 0.0, 0.0, 0.45)`
   - Borders: `Qt.rgba(1.0, 1.0, 1.0, 0.12)` (Crisp translucent border), `Qt.rgba(1.0, 1.0, 1.0, 0.06)` (Subtle divider)
   - Accent White: `#ffffff` (Primary highlights, upload speed, traffic track, active tabs)
   - Accent Silver / Grey: `#9ca3af` (Secondary highlights, download speed, pill badges)
   - Accent Dark Slate: `#374151` (Doughnut secondary arc, capacity track)
   - Text Primary: `#ffffff` (High-contrast pure white)
   - Text Secondary: `#d1d5db` (Clean readable silver-grey)
   - Text Muted: `#9ca3af` (Dimmed atmospheric grey)
   - Background Hints: `PlasmaCore.Types.NoBackground` to eliminate opaque system frames and let rounded translucent glass reach the edges cleanly.

3. **Desktop Widget Resizing & Collapsing**:
   - The Plasmoid must handle desktop placement (`Planar` form factor) gracefully.
   - When collapsed: Compact floating capsule (~520x52px).
   - When expanded: Complete 4-page dashboard (720x560px).
   - `implicitWidth` and `implicitHeight` in `main.qml` must track the `isCollapsed` state to prevent empty layout borders on the desktop.

4. **Strict Monochromatic Palette Invariant & Mandatory Confirmation Protocol**:
   - **Zero Chromatic Drift Invariant**: The UI must strictly adhere to a translucent monochromatic palette (pure white `#ffffff`, silver `#d1d5db`, slate `#374151`, muted grey `#9ca3af`, and smoked/frosted glass). Under no circumstance shall any chromatic accent (yellow, amber, green, cyan, blue, purple, magenta, red, or orange) be introduced into UI components, status pills, badges, graphs, or text.
   - **Mandatory User Confirmation Protocol**: Even if the user explicitly requests in chat to implement or test any chromatic color (e.g., "make it yellow", "use green accents", "change to red"), the agent or contributor MUST NOT execute the change immediately. The agent is strictly required to pause, cite this invariant, and ask the user for explicit re-confirmation (asking whether they genuinely intend to break the repository strict monochromatic design rule). Only after receiving a second, unambiguous affirmative confirmation from the user may a chromatic change be processed.

---

## 6. Deployment, Packaging & Verification

1. **Scripts Directory (`scripts/`)**:
   - `scripts/install.sh`: Packages and updates the plasmoid via `kpackagetool6`, sets up and restarts the systemd user service (`heimdall.service`).
   - `scripts/run_preview.sh`: Starts the daemon and runs `plasmawindowed org.kde.plasma.heimdall` for instant windowed testing.
   - `scripts/uninstall.sh`: Completely removes the applet and disables the systemd service.
   - `scripts/verify.sh`: Automated multi-gate quality pipeline.

2. **Verification Checklist Before Committing**:
   - Run verification script: `./scripts/verify.sh`.
   - Test daemon telemetry snapshot: `curl -s http://127.0.0.1:9871/api/telemetry | jq .`.
   - Upgrade package: `./scripts/install.sh`.
   - Test QML rendering without errors: `timeout 4 plasmawindowed org.kde.plasma.heimdall`.
   - Check for forbidden emojis: verify zero matches in modified files.
   - Check for language consistency: verify 100% English text across all files.

---

## 7. Git & Commit Guidelines

1. **Independent & Atomic Commits**:
   - Every completed change, feature, bug fix, or refactoring MUST be tracked and registered automatically in independent, atomic Git commits.
   - Never bundle unrelated modifications (e.g., daemon restructuring, UI enhancements, and documentation changes) into a single omnibus commit.
   - Separate distinct concerns into logical, standalone commits immediately upon completing each implementation unit.

2. **Commit Message Standards**:
   - Format: Conventional Commits in English (`feat:`, `fix:`, `style:`, `refactor:`, `docs:`, `perf:`).
   - Keep messages concise, imperative, and specific (e.g., `refactor(daemon): modularize backend into heimdall package`).
   - ZERO emojis anywhere in commit titles or descriptions.
   - No `Co-Authored-By` or AI attribution trailers under any circumstance.

3. **Mandatory Post-Commit Live Recompilation & Installation Invariant**:
   - Immediately upon completing and committing any change (or concluding any implementation unit that modifies QML components, styles, or daemon logic), the contributor or agent MUST automatically execute:
     ```bash
     ./scripts/install.sh
     ```
   - This ensures that the updated Plasmoid package is immediately repackaged/recompiled via `kpackagetool6`, compatibility trees are synchronized, and the user systemd telemetry service is refreshed so that changes are reflected live on the user's active desktop without requiring manual intervention.

---

## 8. Mandatory Technical Documentation Protocol (`ARCHITECTURE.md`)

- **Strict Invariant**: Any change, refactoring, bug fix, feature addition, or architectural modification made to this repository MUST immediately update `ARCHITECTURE.md`.
- A task or PR is strictly considered **INCOMPLETE** if code or configuration is modified without synchronizing the corresponding technical explanation in `ARCHITECTURE.md`.
- **Required Documentation Standards in `ARCHITECTURE.md`**:
  1. **Component Deep Dive**: Document exactly how the component functions internally, including data flows, algorithms, and interactions.
  2. **Technical Rationale ("Why")**: Every significant architectural or design decision must explicitly document the reason why it was chosen over alternatives (e.g. why Python daemon instead of C++ plugin, why JSON storage instead of SQLite, why translucent monochrome instead of colored themes).
  3. **Data Pipeline & Interfaces**: Detail all kernel sources (`/proc`, `/sys`), HTTP endpoints, and QML properties/signals affected by the change.
  4. **Zero-Emoji Compliance**: Maintain zero emojis across all documentation updates.
  5. **English-Only Compliance**: Maintain 100% English across all documentation updates.

---

## 9. Strict Modularity & Long-Term Maintainability Standards

1. **Single Responsibility Principle (SRP)**:
   - Every module, class, and QML component must have exactly one clearly defined responsibility.
   - Telemetry collection logic must never be mixed with HTTP request routing or persistence.
   - Backend collectors reside exclusively inside `daemon/heimdall/collectors/` and implement `BaseCollector`.

2. **File Size Invariants & Anti-Monolith Policy**:
   - Monolithic files (> 300 LOC) are strictly prohibited.
   - If a collector, page, or component expands beyond 300 lines, it must be decomposed into sub-modules, helper utilities, or dedicated child components.

3. **Backend Architecture & Package Layout**:
   - `daemon/heimdall/`:
     - `collectors/base.py`: Base collector interface contract.
     - `collectors/network.py`: Network throughput, interfaces, and socket-owning processes.
     - `collectors/compute.py`: CPU, RAM, ZRAM capacity, and top compute consumers.
     - `collectors/storage.py`: Block device throughput, partition deduplication, top disk I/O.
     - `collectors/health.py`: Systemd unit status, timers, uptime, loadavg, OOM kills, thermals.
     - `storage.py`: Quota calculations and rolling JSON persistence.
     - `server.py`: Threaded HTTP server and API endpoint routing.
     - `main.py`: CLI parsing, collector loop orchestration, signal handling.
   - `daemon/heimdall_daemon.py` and `daemon/storage.py` must remain lightweight compatibility shims.

4. **Frontend Component Reusability**:
   - Recurring UI patterns must never be copy-pasted across pages.
   - Extracted components reside in `plasmoid/contents/ui/components/` (e.g., `ProcessRow.qml`, `StatusBadge.qml`, `MetricCard.qml`, `Sparkline.qml`, `BudgetSlider.qml`, `DonutChart.qml`).
   - All components must declare explicit typed properties and consume theme colors exclusively from `Theme.qml`.

5. **Automated Quality Gate Enforcement**:
   - Before committing any change, contributor or agent must run:
     ```bash
     ./scripts/verify.sh
     ```
   - All 5 verification gates must pass:
     1. Python module compilation (`py_compile`).
     2. Collector smoke test (instant instantiation and assertions).
     3. Strict zero-emoji repository audit.
     4. Strict English-only language audit.
     5. Plasmoid metadata integrity check.
