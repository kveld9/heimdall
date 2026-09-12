#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
APPLET_ID="org.kde.plasma.watchcat"

echo "=== [WatchCat] Launching Live Desktop Preview ==="

# 1. Check if daemon is responding on port 9871
if ! curl -s http://127.0.0.1:9871/health > /dev/null 2>&1; then
    echo "[*] Daemon not detected on http://127.0.0.1:9871, starting in background..."
    python3 "$REPO_ROOT/daemon/watchcat_daemon.py" &
    DAEMON_PID=$!
    sleep 1
fi

# 2. Ensure package is installed / up-to-date
"$REPO_ROOT/scripts/install.sh"

# 3. Launch plasmawindowed
echo "[+] Opening Plasmoid in standalone window (plasmawindowed)..."
plasmawindowed "$APPLET_ID"
