# Project conventions

## 配置页 (configGeneral.qml)

- 根元素：`KCM.SimpleKCM`
- Import 必须去掉版本号（`import QtQuick.Controls as QQC2`，不能有 `2.5`）
- 属性别名：`property alias cfg_xxx: control.property`
- ComboBox 的 `cfg_*` 别名必须绑定到 `currentIndex`（Int 枚举），不能绑 `currentValue`
- 配置 schema（`main.xml`）中对应的 entry 类型必须是 `Int`
- `Component.onCompleted` 设置 ComboBox 初始值：
  ```qml
  Component.onCompleted: currentIndex = Plasmoid.configuration.xxx
  ```
- 改完之后 Apply 才会写入配置

## 桥接 (qqmusic-lyrics-bridge)

- 主循环根据 `playerType` 选择音乐播放器：
  - `0` = QQ Music（CDP 连接）
  - `1` = 网易云音乐（未实现）
  - `2` = Spotify（未实现）
- 歌词源 `lyricsSource` 也是 Int 枚举：
  - `0` = both, `1` = native, `2` = lrclib, `3` = netease, `4` = lrclib_first, `5` = netease_first
- 映射表 `_SOURCE_MAP` 在桥接中定义

## 构建与运行

```bash
# 安装 plasmoid
cp -r plasmoid/* ~/.local/share/plasma/plasmoids/com.github.xein.lyrics-osd/

# 安装 systemd 服务
cp qqmusic-lyrics-bridge.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now qqmusic-lyrics-bridge.service

# 环境变量（必需）
mkdir -p ~/.config/plasma-workspace/env/
echo 'export QML_XHR_ALLOW_FILE_READ=1' > ~/.config/plasma-workspace/env/lyrics-osd.sh

# 重启面板
plasmashell --replace &
```
