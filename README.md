# Lyrics OSD

> 在 KDE 任务栏上显示 QQ Music / MoeKoeMusic 的同步歌词

## 安装

```bash
# 一键安装（plasmoid + systemd 服务 + QML 环境变量；无需任何 Python 依赖）
./setup.sh
```

### 手动安装

```bash
# 0. 安装 plasmoid
mkdir -p ~/.local/share/plasma/plasmoids/com.github.xein.lyrics-osd
cp -r plasmoid/* ~/.local/share/plasma/plasmoids/com.github.xein.lyrics-osd/

# 1. 安装 systemd 服务（桥接为纯标准库，直接用系统 python3 运行）
mkdir -p ~/.config/systemd/user
sed "s|/Code/Tools/lyrics-osd|$(pwd)|g" qqmusic-lyrics-bridge.service \
  > ~/.config/systemd/user/qqmusic-lyrics-bridge.service
systemctl --user daemon-reload
systemctl --user enable --now qqmusic-lyrics-bridge.service

# 2. 环境变量（QML 读取本地文件需要）
mkdir -p ~/.config/plasma-workspace/env
cat > ~/.config/plasma-workspace/env/lyrics-osd.sh << 'EOF'
export QML_XHR_ALLOW_FILE_READ=1
EOF

# 3. 重启面板
plasmashell --replace &

# 4. 启动播放器
#    QQ Music：./qqmusic-debug（必须带 debug 端口）
#    MoeKoeMusic：设置 → 系统 → API 模式 → 打开，重启应用

# 5. 添加 widget 到面板
# 右键任务栏 → 编辑模式 → 添加部件 → Lyrics OSD
```

> 桥接脚本只依赖 Python 标准库（自实现 WebSocket/HTTP），系统自带 python3 即可，无需 pip 安装任何包。

## 快速开始

```bash
# 1. 启动 QQ Music（必须带 debug 端口）
./qqmusic-debug

# 2. 确保桥接服务运行
systemctl --user status qqmusic-lyrics-bridge
# 开机自启：systemctl --user enable qqmusic-lyrics-bridge.service
# 查看日志：journalctl --user -u qqmusic-lyrics-bridge -f

# 3. 面板添加 widget
# 右键任务栏 → 编辑模式 → 添加部件 → Lyrics OSD
```

## 使用指南

启动音乐播放器后，桥接脚本自动读取当前播放信息，根据配置的歌词源获取歌词，写入 `/tmp/lyrics-current.txt`。面板上的 widget 每 300ms 读取文件显示当前行。

### QQ Music

必须用 `./qqmusic-debug` 启动（带 CDP 调试端口 9223），桥接脚本通过 Chrome DevTools Protocol 读取播放信息。

### MoeKoeMusic

不需要特殊启动器，MoeKoeMusic 自带 WebSocket API（`ws://127.0.0.1:6520/`），桥接脚本直接订阅实时播放状态和歌词：

1. 打开 MoeKoeMusic **设置 → 系统 → API 模式**，选择“打开”后重启应用（若找不到该项，请升级到最新版，API 模式为较新功能）
2. 右键 Lyrics OSD widget → **Configure → 播放器** 选择 **MoeKoeMusic**

MoeKoeMusic 会实时推送酷狗 KRC 歌词；配置中的“QQ Music 原生”歌词源对该播放器同样生效（即使用内置 KRC）。

若端口被占用或修改过，可用 `./qqmusic-lyrics-bridge --moekoe-port <port>` 覆盖。

### 歌词源（右键 Configure → 歌词来源）
- **全部 (并行)** — QQ Music 下同时请求 lrclib.net 和网易云，先到先用；MoeKoeMusic 下直接使用内置 KRC 歌词
- **QQ Music 原生** — QQ Music 实时读取自带歌词窗口，歌词与播放器完全一致；MoeKoeMusic 下使用内置 KRC 歌词（推荐）
- **仅 lrclib.net / 仅 网易云** — 只使用指定源
- **优先 lrclib / 优先 网易云** — 指定源优先，失败则换另一个（MoeKoeMusic 下失败时回退内置 KRC）

右键 widget → **Configure** 可调整：
- 刷新间隔 (ms)
- 字体大小、加粗、斜体
- 面板宽高
- 播放器（QQ Music / MoeKoeMusic）
- 歌词来源

## 项目结构

```
lyrics-osd/
├── qqmusic-lyrics-bridge      # 桥接守护进程（Python）
├── qqmusic-debug              # QQ Music 启动器（启用 CDP 端口）
├── qqmusic-lyrics-bridge.service  # systemd 用户服务
├── setup.sh                   # 一键安装脚本
└── plasmoid/                  # KDE Plasma 6 widget
    ├── metadata.json
    ├── contents/config/main.xml
    ├── contents/config/config.qml
    └── contents/ui/
        ├── main.qml
        └── configGeneral.qml
```

## 歌词来源

1. lrclib.net — 国际歌曲
2. 网易云音乐 — 中文歌曲（Meting API → Vercel 代理 → 直连 API 三级回退）
3. QQ Music 原生 — 直接读取 QQ Music 歌词窗口（需选择该歌词源）

## 相关文档

- [设计文档](DESIGN.md)

## 协议

MIT
