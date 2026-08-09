# Lyrics OSD

> 在 KDE 任务栏上实时显示 QQ Music / MoeKoeMusic 的同步歌词，支持播放器式上滚动画。

## 功能特性

- 支持 QQ Music（CDP 连接）与 MoeKoeMusic（内置 WebSocket API）
- 歌词来源：播放器内置歌词 / lrclib.net / 网易云，支持并行、优先与回退
- 单行 / 三行 / 两行显示模式，字体大小、加粗、斜体可调
- 歌词切行上滚动画，进度条平滑过渡
- 卡拉 OK 逐字高亮（MoeKoeMusic KRC 歌词），悬停显示封面、歌名、歌手与进度
- 歌词缓存（听过的歌不再重复请求）
- 桥接仅依赖 Python 标准库，无需 pip / venv / 第三方包
- 支持 HTTP 代理（配置页填写）

## 环境要求

### 必需

| 依赖 | 说明 |
| --- | --- |
| KDE Plasma 6 | widget 基于 Plasma 6 API（`X-Plasma-API-Minimum-Version: 6.0`），Plasma 5 不支持 |
| Python 3 | 任意较新的 3.x（3.8+，本机 3.14 实测通过）。仅用标准库，无需安装任何包 |
| systemd 用户会话 | 桥接以 `systemctl --user` 服务运行，KDE 发行版默认都有 |
| 环境变量 | `QML_XHR_ALLOW_FILE_READ=1`，setup.sh 自动写入 `~/.config/plasma-workspace/env/`，重新登录后生效 |

### 播放器（二选一，推荐 MoeKoeMusic）

- **MoeKoeMusic**：需在 **设置 → 系统 → API 模式** 选择“打开”并重启应用；API 模式为较新功能，找不到请升级到最新版
- **QQ Music**：需要 QQ Music 本体，并用仓库里的 `./qqmusic-debug` 启动（带 CDP 调试端口 9223）

### 可选

- **联网**：仅当歌词源选择 lrclib.net / 网易云时需要；MoeKoeMusic 内置 KRC 歌词完全离线可用
- **HTTP 代理**：lrclib / 网易云被墙或变慢时，可在配置页填写

### 不需要

- pip / venv / `websocket-client` / `requests` 等任何 Python 第三方依赖
- sudo / 系统级安装（全部装在用户目录）
- 编译工具链

## 安装

### 一键安装

```bash
./setup.sh
```

脚本自动完成：安装 plasmoid → 安装并启动 systemd 服务 → 写入 QML 环境变量 → 重启面板。

### 手动安装

```bash
# 1. 安装 plasmoid
mkdir -p ~/.local/share/plasma/plasmoids/com.github.xein.lyrics-osd
cp -r plasmoid/* ~/.local/share/plasma/plasmoids/com.github.xein.lyrics-osd/

# 2. 安装 systemd 服务（把路径替换成你的仓库位置）
mkdir -p ~/.config/systemd/user
sed "s|/Code/Tools/lyrics-osd|$(pwd)|g" qqmusic-lyrics-bridge.service \
  > ~/.config/systemd/user/qqmusic-lyrics-bridge.service
systemctl --user daemon-reload
systemctl --user enable --now qqmusic-lyrics-bridge.service

# 3. 环境变量（QML 读取本地文件需要）
mkdir -p ~/.config/plasma-workspace/env
cat > ~/.config/plasma-workspace/env/lyrics-osd.sh << 'EOF'
export QML_XHR_ALLOW_FILE_READ=1
EOF

# 4. 重启面板
plasmashell --replace &

# 5. 添加 widget 到面板
# 右键任务栏 → 编辑模式 → 添加部件 → 搜索 Lyrics OSD → 拖到面板
```

### 更新

重新拉取代码后再次运行 `./setup.sh` 即可（会覆盖旧 plasmoid 并重启服务与面板）。

### 卸载

```bash
systemctl --user disable --now qqmusic-lyrics-bridge
rm -rf ~/.local/share/plasma/plasmoids/com.github.xein.lyrics-osd
rm -f ~/.config/systemd/user/qqmusic-lyrics-bridge.service \
      ~/.config/plasma-workspace/env/lyrics-osd.sh \
      ~/.local/share/applications/qqmusic-lyrics.desktop
plasmashell --replace &
```

## 快速开始

### MoeKoeMusic（推荐）

1. MoeKoeMusic **设置 → 系统 → API 模式 → 打开**，重启应用
2. 右键面板上的 Lyrics OSD widget → **Configure → 播放器** 选择 **MoeKoeMusic**
3. 播放音乐，歌词自动同步

### QQ Music

1. 用 `./qqmusic-debug` 启动 QQ Music（必须带 debug 端口，普通启动无法读取）
2. 右键 widget → **Configure → 播放器** 选择 **QQ Music**

### 服务管理

```bash
systemctl --user status qqmusic-lyrics-bridge    # 状态
journalctl --user -u qqmusic-lyrics-bridge -f    # 实时日志
systemctl --user restart qqmusic-lyrics-bridge   # 重启
```

## 配置（右键 widget → Configure）

| 设置 | 说明 |
| --- | --- |
| 刷新间隔 (ms) | 桥接轮询频率，默认 300 |
| 播放器 | QQ Music / 网易云（未实现）/ Spotify（未实现）/ MoeKoeMusic |
| 歌词来源 | 见下节 |
| 字号 / 加粗 / 斜体 | 歌词文字样式 |
| 宽度 / 高度 | widget 在面板上的尺寸 |
| 显示模式 | 单行 / 三行 / 两行·当前在上 / 两行·当前在下 |
| 进度条 | 显示/隐藏播放进度 |
| HTTP 代理 | 代理 lrclib / 网易云请求，如 `http://127.0.0.1:7890` |
| 清空歌词缓存 | 一键删除 `~/.cache/lyrics-osd` 下缓存的歌词 |

## 歌词来源

| 模式 | QQ Music | MoeKoeMusic |
| --- | --- | --- |
| 全部（并行） | 同时请求 lrclib + 网易云，先到先用 | 直接使用内置 KRC 歌词 |
| QQ Music 原生 | 实时读取播放器自带歌词窗口（推荐） | 使用内置 KRC 歌词（推荐） |
| 仅 lrclib.net | 只用 lrclib | 只用 lrclib |
| 仅 网易云 | 只用网易云 | 只用网易云 |
| 优先 lrclib / 网易云 | 主源失败换另一个 | 主源失败回退内置 KRC |

在线源获取顺序：lrclib.net（国际歌曲）→ 网易云（Meting API → Vercel 代理 → 直连三级回退）。

## 工作原理

```
QQ Music (Electron) ──CDP 9223──┐
                                ├─▶ qqmusic-lyrics-bridge (Python 标准库)
MoeKoeMusic (Electron) ──WS 6520┘
                                    │  写入 /tmp/lyrics-current.txt
                                    │       /tmp/lyrics-meta.json
                                    ▼
                              plasmoid (QML) 轮询读取 → 面板显示
```

桥接按配置的 `playerType` 选择后端：QQ Music 通过 Chrome DevTools Protocol 注入页面提取播放信息；MoeKoeMusic 通过其 WebSocket API 实时接收播放状态与 KRC 歌词（事件驱动，零轮询）。歌词匹配当前播放位置后写入 `/tmp` 两个文件，widget 每 250ms 读取并显示。

## 命令行参数

```bash
./qqmusic-lyrics-bridge [--debug-port PORT] [--moekoe-port PORT] [--interval MS]
```

| 参数 | 默认 | 说明 |
| --- | --- | --- |
| `--debug-port` | 9223 | QQ Music CDP 调试端口 |
| `--moekoe-port` | 6520 | MoeKoeMusic WebSocket API 端口（端口被占用/修改时覆盖） |
| `--interval` | 读配置 | 轮询间隔 (ms) |

## 常见问题

### 找不到“API 模式”选项
MoeKoeMusic 的 API 模式是较新功能，位置在 **设置 → 系统 → API 模式**。没有该项请升级到最新版。

### MoeKoeMusic 提示“API 服务启动失败”
端口 6521 被残留的 API 子进程占用（通常是上次没从托盘退出、直接注销导致）。清掉后重启应用即可：

```bash
pkill -f app_linux
```

平时建议从托盘“退出”MoeKoeMusic 而不是直接注销。

### 面板不显示歌词

1. 确认桥接在跑：`systemctl --user status qqmusic-lyrics-bridge`
2. 确认环境变量已生效：`cat ~/.config/plasma-workspace/env/lyrics-osd.sh`，若文件存在但之前没显示，**重新登录一次**
3. 确认 widget 配置里播放器与你的播放器一致
4. 查看日志：`journalctl --user -u qqmusic-lyrics-bridge -f`

### QQ Music 不显示歌词
必须用 `./qqmusic-debug` 启动（带 `--remote-debugging-port=9223`），普通方式启动无法读取。

### MoeKoeMusic 端口被占用
用 `./qqmusic-lyrics-bridge --moekoe-port <端口>` 覆盖，并把服务文件里的 ExecStart 加上该参数。

## 项目结构

```
lyrics-osd/
├── qqmusic-lyrics-bridge          # 桥接守护进程（纯 Python 标准库）
├── qqmusic-debug                  # QQ Music 启动器（启用 CDP 端口 9223）
├── qqmusic-lyrics-bridge.service  # systemd 用户服务模板
├── setup.sh                       # 一键安装 / 更新脚本
├── plasmoid/                      # KDE Plasma 6 widget
│   ├── metadata.json
│   ├── contents/config/main.xml
│   ├── contents/config/config.qml
│   └── contents/ui/
│       ├── main.qml
│       └── configGeneral.qml
├── CHANGELOG.md
└── DESIGN.md
```

## 相关文档

- [设计文档](DESIGN.md)
- [更新日志](CHANGELOG.md)

## 协议

MIT
