#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PLASMOID_DIR="$REPO_ROOT/plasmoid"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
APPLET_ID="org.kde.plasma.heimdall"

echo "=== [Heimdall] Installing Plasmoid into Plasma 6 ==="

# Check kpackagetool6
if ! command -v kpackagetool6 &> /dev/null; then
    echo "[-] Error: kpackagetool6 not found. Please install plasma-workspace / kpackage."
    exit 1
fi

# Clean up legacy watchcat applet if registered
if kpackagetool6 -t Plasma/Applet --list | grep -q "org.kde.plasma.watchcat"; then
    echo "[*] Removing legacy watchcat applet registration..."
    kpackagetool6 -t Plasma/Applet -r "org.kde.plasma.watchcat" || true
    rm -rf "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.watchcat" || true
fi

# Install or Upgrade Plasmoid
if kpackagetool6 -t Plasma/Applet --list | grep -q "$APPLET_ID"; then
    echo "[*] Upgrading existing Plasmoid package..."
    kpackagetool6 -t Plasma/Applet -u "$PLASMOID_DIR"
else
    echo "[*] Installing Plasmoid package..."
    kpackagetool6 -t Plasma/Applet -i "$PLASMOID_DIR"
fi

# Ensure user directory for Plasmoids is linked
USER_PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/$APPLET_ID"
if [ ! -d "$USER_PLASMOID_DIR" ]; then
    mkdir -p "$HOME/.local/share/plasma/plasmoids"
    ln -sfn "$PLASMOID_DIR" "$USER_PLASMOID_DIR"
fi

echo "[+] Plasmoid successfully installed to $USER_PLASMOID_DIR"

# Stop legacy watchcat service if running
if systemctl --user is-active --quiet watchcat.service 2>/dev/null; then
    echo "[*] Stopping legacy watchcat service..."
    systemctl --user stop watchcat.service || true
    systemctl --user disable watchcat.service || true
    rm -f "$SYSTEMD_USER_DIR/watchcat.service"
fi

# Install Systemd User Service
echo "=== [Heimdall] Configuring Background Telemetry Daemon ==="
mkdir -p "$SYSTEMD_USER_DIR"

cat <<EOF > "$SYSTEMD_USER_DIR/heimdall.service"
[Unit]
Description=Heimdall Zero-Jank Telemetry Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $REPO_ROOT/daemon/heimdall_daemon.py
Restart=always
RestartSec=2
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now heimdall.service

echo "[+] Heimdall Telemetry Daemon enabled and started via systemd user session."
echo "=== Installation complete! You can now add 'Heimdall' to your desktop or panel. ==="
