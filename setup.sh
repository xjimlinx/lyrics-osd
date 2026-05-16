#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLASMOID_ID="com.github.xein.lyrics-osd"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"
USER_DESKTOP="$HOME/.local/share/applications/qqmusic-lyrics.desktop"
SYSTEMD_DIR="$HOME/.config/systemd/user"

echo "========================================="
echo " Lyrics OSD - QQ Music + KDE Panel Setup"
echo "========================================="
echo ""

# ── 1. Install plasmoid ──
echo "=> [1/6] Installing plasmoid..."
mkdir -p "$PLASMOID_DIR"
cp -r "$SCRIPT_DIR/plasmoid/"* "$PLASMOID_DIR/"
echo "  Plasmoid ID: $PLASMOID_ID"

# ── 2. Create debug-enabled launcher ──
echo "=> [2/6] Creating QQ Music launcher with debug port..."
chmod +x "$SCRIPT_DIR/qqmusic-debug"
chmod +x "$SCRIPT_DIR/qqmusic-lyrics-bridge"

# Patch the main desktop file to add debug port if user hasn't customized it
SYSTEM_DESKTOP="/usr/share/applications/qqmusic.desktop"
mkdir -p "$(dirname "$USER_DESKTOP")"

if grep -q "remote-debugging-port" "$SYSTEM_DESKTOP" 2>/dev/null; then
    echo "  Debug port already in system desktop file"
else
    cat > "$USER_DESKTOP" << DESKEOF
[Desktop Entry]
Name=QQ Music (Lyrics)
Name[zh_CN]=QQ音乐 (歌词版)
Exec=$SCRIPT_DIR/qqmusic-debug %U
Terminal=false
Type=Application
Icon=qqmusic
StartupWMClass=qqmusic
Comment=QQ Music with synced lyrics on KDE panel
Categories=AudioVideo;
DESKEOF
    echo "  Created: $USER_DESKTOP"
fi

# ── 3. Stop existing QQ Music and restart with debug port ──
echo "=> [3/6] Checking QQ Music process..."
if pgrep -f "qqmusic" > /dev/null 2>&1; then
    echo "  QQ Music is running. Please close it and re-launch using:"
    echo "    $SCRIPT_DIR/qqmusic-debug"
    echo "  (or launch 'QQ Music (Lyrics)' from app menu)"
fi

# ── 4. Install systemd service ──
echo "=> [4/6] Installing lyrics bridge service..."
mkdir -p "$SYSTEMD_DIR"
cp "$SCRIPT_DIR/qqmusic-lyrics-bridge.service" "$SYSTEMD_DIR/"
systemctl --user daemon-reload
systemctl --user stop qqmusic-lyrics-bridge.service 2>/dev/null || true
systemctl --user enable --now qqmusic-lyrics-bridge.service
echo "  Service installed and started."

# ── 5. Wait and verify bridge working ──
echo "=> [5/6] Waiting for bridge to connect to QQ Music..."
for i in $(seq 1 10); do
    sleep 1
    if [ -f /tmp/lyrics-current.txt ] && grep -qv "No song detected" /tmp/lyrics-current.txt 2>/dev/null; then
        lyric=$(cat /tmp/lyrics-current.txt)
        echo "  Bridge working! Current lyric: $lyric"
        break
    fi
done
if [ ! -f /tmp/lyrics-current.txt ] || grep -q "No song detected" /tmp/lyrics-current.txt 2>/dev/null; then
    echo "  Waiting for QQ Music with debug port..."
    echo "  (If QQ Music isn't running with --remote-debugging-port=9223, lyrics won't appear)"
fi

# ── 6. Restart plasmashell ──
echo "=> [6/6] Reloading plasmashell to pick up new widget..."
plasmashell --replace &>/dev/null &
disown
sleep 2

echo ""
echo "========================================="
echo " Setup complete!"
echo ""
echo " Widget: Right-click taskbar -> Edit Mode -> Add Widgets"
echo "         Search 'Lyrics OSD' -> drag to panel"
echo ""
echo " QQ Music launcher in app menu: 'QQ Music (Lyrics)'"
echo " Or run: $SCRIPT_DIR/qqmusic-debug"
echo ""
echo " Manage service:"
echo "   status: systemctl --user status qqmusic-lyrics-bridge"
echo "   logs:   journalctl --user -u qqmusic-lyrics-bridge -f"
echo "   stop:   systemctl --user stop qqmusic-lyrics-bridge"
echo ""
echo " Lyrics sources: lrclib.net -> Netease Cloud Music (auto fallback)"
echo "========================================="
