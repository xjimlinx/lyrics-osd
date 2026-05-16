# Changelog

## [0.2.0] - 2026-05-17

### Added
- 并行请求 lrclib + 网易云，任一返回即可
- 歌词本地缓存 (~/.cache/lyrics-osd/)，重复播放秒出
- QQ Music 快捷启动器 qqmusic-debug

### Changed
- 复用 CDP WebSocket 连接，切歌不再重建
- 切歌时先写歌手-歌名回退，歌词后台异步加载

### Fixed
- 配置页标题左对齐
- 刷新间隔下限从 100ms 降到 50ms

## [0.1.0] - 2026-05-16

### Added
- 通过 CDP 连接 QQ Music 提取当前播放信息
- lrclib.net + 网易云音乐双来源歌词获取
- LRC 时间线解析与同步显示
- KDE Plasma 6 面板 widget（compactRepresentation）
- 配置页：刷新间隔、字体、宽高设置
- 桥接进程自动读取 plasmoid 配置实现轮询同步
- systemd 用户服务实现开机自启
- 一键安装脚本 setup.sh
