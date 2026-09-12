#!/usr/bin/env bash
set -e

APPLET_ID="org.kde.plasma.watchcat"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "=== [WatchCat] Uninstalling Plasmoid and Daemon ==="

systemctl --user stop watchcat.service 2>/dev/null || true
systemctl --user disable watchcat.service 2>/dev/null || true
rm -f "$SYSTEMD_USER_DIR/watchcat.service"
systemctl --user daemon-reload 2>/dev/null || true

kpackagetool6 -t Plasma/Applet -r "$APPLET_ID" 2>/dev/null || true
rm -rf "$HOME/.local/share/plasma/plasmoids/$APPLET_ID"

echo "[+] WatchCat successfully removed."
