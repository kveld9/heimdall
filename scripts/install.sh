#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PLASMOID_DIR="$REPO_ROOT/plasmoid"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
APPLET_ID="org.kde.plasma.watchcat"

echo "=== [WatchCat] Installing Plasmoid into Plasma 6 ==="

# Check kpackagetool6
if ! command -v kpackagetool6 &> /dev/null; then
    echo "[-] Error: kpackagetool6 not found. Please install plasma-workspace / kpackage."
    exit 1
fi

# Install or Upgrade Plasmoid
if kpackagetool6 -t Plasma/Applet --list | grep -q "$APPLET_ID"; then
    echo "[*] Upgrading existing Plasmoid package..."
    kpackagetool6 -t Plasma/Applet -u "$PLASMOID_DIR"
else
    echo "[*] Installing Plasmoid package..."
    kpackagetool6 -t Plasma/Applet -i "$PLASMOID_DIR"
fi

# Ensure user directory for Plasmoids is linked if kpackagetool6 didn't copy directly
USER_PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/$APPLET_ID"
if [ ! -d "$USER_PLASMOID_DIR" ]; then
    mkdir -p "$HOME/.local/share/plasma/plasmoids"
    ln -sfn "$PLASMOID_DIR" "$USER_PLASMOID_DIR"
fi

echo "[+] Plasmoid successfully installed to $USER_PLASMOID_DIR"

# Install Systemd User Service
echo "=== [WatchCat] Configuring Background Telemetry Daemon ==="
mkdir -p "$SYSTEMD_USER_DIR"

cat <<EOF > "$SYSTEMD_USER_DIR/watchcat.service"
[Unit]
Description=WatchCat Zero-Jank Telemetry Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $REPO_ROOT/daemon/watchcat_daemon.py
Restart=always
RestartSec=2
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now watchcat.service

echo "[+] WatchCat Telemetry Daemon enabled and started via systemd user session."
echo "=== Installation complete! You can now add 'WatchCat' to your desktop or panel. ==="
