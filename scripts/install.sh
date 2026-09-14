#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PLASMOID_DIR="$REPO_ROOT/plasmoid"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
APPLET_ID="org.kde.plasma.heimdall"
APPLET_VERSION=$(grep -oP '"Version":\s*"\K[^"]+' "$PLASMOID_DIR/metadata.json" || echo "1.0.0")

echo "=== [Heimdall] Installing Plasmoid into Plasma 6 ==="

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

# Maintain backward compatibility for existing desktop/panel instances (org.kde.plasma.watchcat)
COMPAT_WATCHCAT_DIR="$HOME/.local/share/plasma/plasmoids/org.kde.plasma.watchcat"
echo "[*] Updating backward compatibility wrapper for org.kde.plasma.watchcat..."
mkdir -p "$COMPAT_WATCHCAT_DIR"
cat <<EOF > "$COMPAT_WATCHCAT_DIR/metadata.json"
{
    "KPackageStructure": "Plasma/Applet",
    "KPlugin": {
        "Authors": [
            {
                "Email": "maintainer@heimdall.local",
                "Name": "Kveld & Antigravity"
            }
        ],
        "Category": "System Information",
        "Description": "Heimdall - Aesthetic Zero-Jank System Monitor & Network Telemetry Plasmoid (Legacy Compatibility)",
        "Icon": "network-workgroup",
        "Id": "org.kde.plasma.watchcat",
        "License": "GPL-3.0+",
        "Name": "Heimdall",
        "Version": "$APPLET_VERSION"
    },
    "X-Plasma-API-Minimum-Version": "6.0"
}
EOF
rm -rf "$COMPAT_WATCHCAT_DIR/contents"
cp -r "$PLASMOID_DIR/contents" "$COMPAT_WATCHCAT_DIR/"

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

systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now heimdall.service 2>/dev/null || true
systemctl --user restart heimdall.service 2>/dev/null || true

echo "[+] Heimdall Telemetry Daemon enabled and started via systemd user session."

# Purge Plasma QML bytecode cache
echo "[*] Purging Plasma QML bytecode cache..."
rm -rf "$HOME/.cache/plasmashell/qmlcache" "$HOME/.cache/plasmawindowed/qmlcache"

# Reload plasmashell if active to reflect visual changes immediately
if systemctl --user is-active --quiet plasma-plasmashell.service 2>/dev/null; then
    echo "[*] Reloading active Plasma shell to refresh desktop plasmoids..."
    systemctl --user restart plasma-plasmashell.service
fi

echo "=== Installation complete! You can now add 'Heimdall' to your desktop or panel. ==="
