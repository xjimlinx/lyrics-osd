# Lyrics OSD

> 在 KDE 任务栏上显示 QQ Music 的同步歌词

## 安装

```bash
./setup.sh
```

## 快速开始

```bash
# 1. 用 debug 端口启动 QQ Music
./qqmusic-debug

# 2. 确保桥接服务运行
systemctl --user status qqmusic-lyrics-bridge

# 3. 面板添加 widget
# 右键任务栏 → 编辑模式 → 添加部件 → Lyrics OSD
```

## 使用指南

启动 QQ Music 后，桥接脚本自动通过 Chrome DevTools Protocol 读取当前播放信息，从 lrclib.net 或网易云音乐获取 LRC 歌词，写入 `/tmp/lyrics-current.txt`。面板上的 widget 每 300ms 读取文件显示当前行。

右键 widget → **Configure** 可调整：
- 刷新间隔 (ms)
- 字体大小、加粗、斜体
- 面板宽高

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
2. 网易云音乐 — 中文歌曲（自动回退）

## 相关文档

- [设计文档](DESIGN.md)

## 协议

MIT
