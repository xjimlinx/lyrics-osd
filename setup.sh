#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLASMOID_ID="com.github.xein.lyrics-osd"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"
USER_DESKTOP="$HOME/.local/share/applications/qqmusic-lyrics.desktop"
SYSTEMD_DIR="$HOME/.config/systemd/user"

echo "========================================="
echo " Lyrics OSD - QQ Music + MoeKoeMusic + KDE"
echo "========================================="
echo ""

if ! command -v python3 >/dev/null 2>&1; then
    echo "错误：未找到 python3，请先安装（KDE 发行版一般自带）" >&2
    exit 1
fi

# ── 1. Install plasmoid ──
echo "=> [1/6] Installing plasmoid..."
mkdir -p "$PLASMOID_DIR"
cp -r "$SCRIPT_DIR/plasmoid/"* "$PLASMOID_DIR/"
chmod +x "$SCRIPT_DIR/qqmusic-debug"
chmod +x "$SCRIPT_DIR/qqmusic-lyrics-bridge"
echo "  Plasmoid ID: $PLASMOID_ID"

# ── 2. Create debug-enabled QQ Music launcher ──
echo "=> [2/6] Creating QQ Music launcher with debug port..."
SYSTEM_DESKTOP="/usr/share/applications/qqmusic.desktop"
mkdir -p "$(dirname "$USER_DESKTOP")"

if grep -q "remote-debugging-port" "$SYSTEM_DESKTOP" 2>/dev/null; then
    echo "  Debug port already in system desktop file"
elif ! command -v qqmusic >/dev/null 2>&1 && [ ! -x /usr/bin/qqmusic ]; then
    echo "  qqmusic not found, skipping QQ Music launcher (MoeKoeMusic works without it)"
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

# ── 3. Install systemd service (runs the bridge with the system python3) ──
echo "=> [3/6] Installing lyrics bridge service..."
mkdir -p "$SYSTEMD_DIR"
cat > "$SYSTEMD_DIR/qqmusic-lyrics-bridge.service" << UNITEOF
[Unit]
Description=Music Lyrics Bridge
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=$SCRIPT_DIR/qqmusic-lyrics-bridge
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
UNITEOF
systemctl --user daemon-reload
systemctl --user stop qqmusic-lyrics-bridge.service 2>/dev/null || true
systemctl --user enable --now qqmusic-lyrics-bridge.service
echo "  Service installed and started."

# ── 4. QML env (plasmoid reads /tmp files via XHR) ──
echo "=> [4/6] Creating QML environment file..."
mkdir -p "$HOME/.config/plasma-workspace/env"
cat > "$HOME/.config/plasma-workspace/env/lyrics-osd.sh" << 'ENVEOF'
export QML_XHR_ALLOW_FILE_READ=1
ENVEOF
echo "  Created: $HOME/.config/plasma-workspace/env/lyrics-osd.sh"

# ── 5. Wait and verify bridge working ──
echo "=> [5/6] Waiting for bridge to connect to a player..."
sleep 2
if [ -f /tmp/lyrics-current.txt ] && grep -qv "No song detected" /tmp/lyrics-current.txt 2>/dev/null; then
    lyric=$(cat /tmp/lyrics-current.txt)
    echo "  Bridge working! Current lyric: $lyric"
else
    echo "  Waiting for a player..."
    echo "  - QQ Music: launch 'QQ Music (Lyrics)' from app menu (debug port 9223)"
    echo "  - MoeKoeMusic: enable 设置 → 系统 → API 模式, then restart the app"
fi

# ── 6. Restart plasmashell ──
echo "=> [6/6] Reloading plasmashell to pick up new widget..."
if systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
    systemctl --user restart plasma-plasmashell.service
else
    setsid nohup plasmashell --replace >/tmp/lyrics-osd-plasmashell.log 2>&1 < /dev/null &
fi
sleep 2

echo ""
echo "========================================="
echo " Setup complete!"
echo ""
echo " Widget: Right-click taskbar -> Edit Mode -> Add Widgets"
echo "         Search 'Lyrics OSD' -> drag to panel"
echo ""
echo " Player: right-click widget -> Configure -> 播放器"
echo "   - QQ Music: use the 'QQ Music (Lyrics)' launcher"
echo "   - MoeKoeMusic: enable 设置 → 系统 → API 模式 and restart the app"
echo ""
echo " Manage service:"
echo "   status: systemctl --user status qqmusic-lyrics-bridge"
echo "   logs:   journalctl --user -u qqmusic-lyrics-bridge -f"
echo "   stop:   systemctl --user stop qqmusic-lyrics-bridge"
echo ""
echo " No Python dependencies needed: the bridge only uses the system python3"
echo "========================================="
