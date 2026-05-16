# Lyrics OSD 设计文档

## 概述

在 KDE Plasma 6 的任务栏上实时显示 QQ Music 的同步歌词。QQ Music Linux 版不原生支持 MPRIS2，因此无法直接使用现有歌词 widget。本项目通过 Chrome DevTools Protocol 注入 QQ Music 进程获取播放信息，辅以在线歌词 API 实现同步歌词功能。

## 架构

```
QQ Music (Electron)
    │  --remote-debugging-port=9223
    ▼
qqmusic-lyrics-bridge (Python 守护进程)
    │  CDP → 提取歌手/歌名/进度
    │  lrclib.net / 网易云 → 获取 LRC
    │  写入 /tmp/lyrics-current.txt
    ▼
plasmoid (QML)
    │  XMLHttpRequest 轮询读取
    ▼
KDE 任务栏显示
```

## 核心模块

### qqmusic-lyrics-bridge

- **CDP 连接** — 通过 Chrome DevTools Protocol 连接 QQ Music 的 Electron 实例，获取播放信息
- **歌曲提取** — 从 `.player_cont` DOM 元素解析当前歌曲/歌手，从 `<audio>` 元素获取播放进度
- **歌词获取** — lrclib.net 为主，网易云音乐为中文歌曲回退源
- **LRC 同步** — 解析 LRC 时间线，匹配当前播放位置，写入输出文件

### plasmoid

- **main.qml** — `PlasmoidItem` 作为根，`preferredRepresentation: compactRepresentation` 实现在面板上直接显示文字
- **configGeneral.qml** — `KCM.SimpleKCM` + `Kirigami.FormLayout` 配置页
- **config/config.qml** — `ConfigModel` 注册配置标签页
- **通信** — 通过 `/tmp/lyrics-current.txt` 文件与桥接进程共享数据

## 数据流

1. 桥接每 300ms 通过 CDP 获取当前歌曲标题、歌手、播放位置
2. 切歌时触发在线歌词下载，解析为 LRC 时间线 `[(timestamp, text), ...]`
3. 每 300ms 在 LRC 时间线中定位当前行
4. 写入输出文件
5. plasmoid 每 `refreshInterval` ms 读取文件，更新显示

## 配置

KConfig XT 格式，存储在 `~/.config/plasma-org.kde.plasma.desktop-appletsrc`：
- `refreshInterval` — 轮询间隔 (ms)，默认 300
- `fontPixelSize` — 字号，默认 16
- `fontBold` / `fontItalic` — 字体样式
- `widgetWidth` / `widgetHeight` — 面板宽高

桥接进程启动时自动读取相同的配置文件，确保轮询同步。

## 环境变量

- `QML_XHR_ALLOW_FILE_READ=1` — 允许 QML 通过 XMLHttpRequest 读取本地文件
