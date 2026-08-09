# Changelog

## [0.7.2] - 2026-08-10

### Changed
- 移除悬浮封面提示，专辑封面直接显示在 widget 左侧（高度略小于任务栏），无封面时自动隐藏
- 卡拉 OK 逐字改为播放器风格：唱到的字高亮、未唱到的字半透明暗色，200ms 渐入更丝滑

## [0.7.1] - 2026-08-10

### Fixed
- 悬浮封面改为显式 ToolTipArea 触发，解决面板中内置 tooltip 不显示的问题
- 快速切歌时立即写入新歌 fallback，widget 不再残留旧歌词；封面改为异步下载，慢 CDN 不再阻塞歌词更新

### Changed
- 卡拉 OK 逐字改为 30fps 播放推进，轮询降到 150ms，点亮与进度条连续无跳变
- 悬浮封面高度跟随任务栏高度（略小），不再是固定大图

## [0.7.0] - 2026-08-10

### Added
- 卡拉 OK 逐字高亮：KRC 字符级时间戳不再丢弃，当前行歌词逐字点亮（带颜色过渡动画）
- 悬浮提示：鼠标悬停显示专辑封面、歌名、歌手与播放进度（MoeKoeMusic 封面自动下载）

### Changed
- `parse_krc` 保留字符级时间轴，返回 `(time, text, chars)` 结构；无字符时间的 LRC/原生歌词自动回退为整行显示
- `/tmp/lyrics-meta.json` 新增 `char_times`、`line_start`、`cover`、`cover_ver` 字段

## [0.6.1] - 2026-08-10

### Changed
- 重构：plasmoid 配置读取收敛为统一 helper，去掉 4 处重复代码
- widget 配置改为 QML 响应式绑定，移除 500ms 配置轮询定时器
- `qqmusic-debug` 自动探测 QQ Music 可执行文件路径
- setup.sh 增加 python3 前置检查

### Fixed
- CDP 消息 id 改用自增计数，避免同毫秒内 id 碰撞
- 删除网易云直连函数中不可达的死代码

## [0.6.0] - 2026-08-10

### Changed
- 桥接改为纯 Python 标准库实现（自研 WebSocket 客户端 + urllib HTTP），不再需要 pip 安装 websocket-client / requests，系统自带 python3 即可运行
- setup.sh 不再创建 venv，systemd 服务直接执行桥接脚本
- 配置页的“宽度/高度”设置现在真正作用于 widget
- 歌词切换带播放器式上滚动画，进度条平滑过渡

### Fixed
- 无歌曲时同步清空 meta，widget 不再残留上一首歌
- meta 写入改为原子写（临时文件 + rename）
- 移除未使用的死代码与无意义的后台等待

## [0.5.0] - 2026-08-10

### Added
- MoeKoeMusic 播放器支持：通过内置 WebSocket API（ws://127.0.0.1:6520）实时订阅播放状态与 KRC 歌词
- KRC 歌词解析（含 offset 偏移、字符级时间标签剥离）
- `--moekoe-port` 参数覆盖默认端口
- 配置页播放器列表新增 MoeKoeMusic

### Changed
- 桥接启动日志同时输出 CDP 与 MoeKoeMusic WS 端口

## [0.4.0] - 2026-05-17

### Added
- 进度条独立开关，单行模式也支持进度条
- 原生模式逐行录制 LRC（带时间戳），听一遍即可缓存
- 原生模式优先读缓存，有缓存时自动转 LRC 显示（多行+进度条）
- 原生模式进度条支持（duration/progress 用实际值）
- HTTP 代理设置

### Fixed
- 原生模式+缓存 LRC 时歌词不更新
- 原生录制不覆盖已有缓存

## [0.3.1] - 2026-05-17

## [0.3.0] - 2026-05-17

### Added
- QQ Music 原生歌词模式：实时读取 lyric.html 页面
- 播放器选择（QQ Music / 网易云 / Spotify），后两者为空壳
- 配置页清空歌词缓存按钮
- 实时歌词：前后句 + 播放进度条
- 显示模式切换（单行 / 三行 / 两行当前在上 / 两行当前在下）
- 缓存歌曲 ID，同一首歌不重复搜索

### Changed
- 歌词源 ComboBox 改为 Int 枚举类型
- 字体、尺寸、刷新间隔改为即时写入配置
- 多行模式按比例分配高度（28/38/28）

### Fixed
- 快切歌时不闪 No song detected
- 后台歌词完成时检查歌曲是否已切，丢弃过期结果
- 直线搜索 + Meting API 取网易云歌词，无需代理
- 搜索同时匹配歌名+歌手，防止多版本误命中

## [0.2.0] - 2026-05-17

### Added
- 并行请求 lrclib + 网易云，任一返回即可
- 歌词本地缓存 (~/.cache/lyrics-osd/)，重复播放秒出
- QQ Music 快捷启动器 qqmusic-debug
- Meting API 网易云歌词源，无需代理
- 直连搜索 ID + Meting API 取歌词，不依赖代理
- 配置页可切换歌词源（全部并行 / QQ Music 原生 / lrclib / 网易云 / 优先）
- QQ Music 原生歌词模式：实时读 lyric.html 页面，歌词与 QQ Music 一致
- 提取专辑名加入网易云搜索关键词，提升多版本匹配度
- 缓存歌曲 ID，同曲不重复搜索
- 配置页清空歌词缓存按钮
- 歌词下载扔后台线程，主循环不卡顿

### Changed
- 复用 CDP WebSocket 连接，切歌不再重建
- 切歌时先写歌手-歌名回退，歌词后台异步加载
- 网易云歌词：代理失败自动回退到原生 API
- 超时调整：Vercel 代理 25s，直连 API 6s
- 歌词源 ComboBox 类型从 String 改为 Int 枚举，点 Apply 保存

### Fixed
- 配置页标题左对齐
- 刷新间隔下限从 100ms 降到 50ms
- 快切歌时不覆盖已有内容，轮询从 1s 降到 300ms
- 后台歌词完成时检查歌曲是否已切，丢弃过期结果
- 搜索歌名+歌手双匹配，防止多版本误命中
- 原生模式全路径跳过 LRC 写入，仅显示 lyric.html 内容

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
