#!/usr/bin/env bash
set -e

APPLET_ID="org.kde.plasma.heimdall"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "=== [Heimdall] Uninstalling Plasmoid and Daemon ==="

systemctl --user stop heimdall.service 2>/dev/null || true
systemctl --user disable heimdall.service 2>/dev/null || true
rm -f "$SYSTEMD_USER_DIR/heimdall.service"

# Also clean legacy watchcat service if present
systemctl --user stop watchcat.service 2>/dev/null || true
systemctl --user disable watchcat.service 2>/dev/null || true
rm -f "$SYSTEMD_USER_DIR/watchcat.service"

systemctl --user daemon-reload 2>/dev/null || true

kpackagetool6 -t Plasma/Applet -r "$APPLET_ID" 2>/dev/null || true
rm -rf "$HOME/.local/share/plasma/plasmoids/$APPLET_ID"
kpackagetool6 -t Plasma/Applet -r "org.kde.plasma.watchcat" 2>/dev/null || true
rm -rf "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.watchcat"

echo "[+] Heimdall successfully removed."
