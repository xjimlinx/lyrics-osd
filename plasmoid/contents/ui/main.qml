import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation
    Layout.preferredWidth: Plasmoid.configuration.widgetWidth
    Layout.preferredHeight: Plasmoid.configuration.widgetHeight

    property string lyric: "♪"
    property string prevLine: ""
    property string nextLine: ""
    property string dLyric: "♪"      // currently displayed line
    property string dPrev: ""
    property string dNext: ""
    property real progress: 0
    property int dm: Plasmoid.configuration.displayMode
    property int fs: Plasmoid.configuration.fontPixelSize
    property int fw: Plasmoid.configuration.fontBold ? Font.Bold : Font.Normal
    property bool fi: Plasmoid.configuration.fontItalic
    property bool sp: Plasmoid.configuration.showProgress
    property bool karaokeMode: Plasmoid.configuration.karaokeMode
    property bool showCover: Plasmoid.configuration.showCover

    // 歌曲信息（封面与逐字推进用）
    property real position: 0
    property real lineStart: 0
    property real duration: 0
    property bool playing: false
    property real metaTime: 0       // 最近一次 meta 读取的系统时间 (ms)

    // 卡拉 OK 逐字高亮
    property var lyricChars: []
    property var charTimes: []
    property bool karaoke: root.karaokeMode
                          && root.charTimes.length === root.lyricChars.length
                          && root.lyricChars.length > 0
    property real lineElapsed: 0

    // 封面
    property string coverPath: ""
    property int coverVer: 0
    property string coverSource: ""

    function lineSlot() {
        if (lyricArea.height <= 0) return 0
        if (root.dm === 0) return lyricArea.height
        if (root.dm === 1) return lyricArea.height * 0.4
        return lyricArea.height * 0.5
    }

    function rollTo(p, c, n) {
        // Player-style roll: new content starts one slot below and slides up.
        dPrev = p; dLyric = c; dNext = n
        var slot = lineSlot()
        if (slot > 0) {
            roll.y = slot
            rollAnim.start()
        } else {
            roll.y = 0
        }
    }

    function buildChars(text, times) {
        // 只有字符时间戳与正文等长时才逐字；karaoke 为绑定，配置改动即时生效
        lyricChars = text.split("")
        charTimes = (times && times.length === lyricChars.length) ? times : []
    }

    function charColor(i) {
        // 每个字在它自己的时间点前后平滑渐亮：暗色 → 高亮色（120ms）
        if (!root.karaoke || i >= root.charTimes.length) return Kirigami.Theme.textColor
        var base = Kirigami.Theme.textColor
        var dark = Qt.rgba(base.r, base.g, base.b, 0.42)
        var hl = Kirigami.Theme.highlightColor
        var t = (root.lineElapsed - root.charTimes[i]) / 0.12
        t = Math.max(0, Math.min(1, t))
        if (t >= 1) return hl
        return Qt.rgba(
            dark.r + (hl.r - dark.r) * t,
            dark.g + (hl.g - dark.g) * t,
            dark.b + (hl.b - dark.b) * t,
            dark.a + (hl.a - dark.a) * t
        )
    }

    function readMeta() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/lyrics-meta.json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try {
                    var m = JSON.parse(xhr.responseText)
                    var t = m.current_line || m.title || "♪"
                    if (m.artist && t === m.title) t = m.artist + " - " + t
                    var p = m.prev_line || ""
                    var n = m.next_line || ""
                    if (t !== lyric) {
                        prevLine = p; lyric = t; nextLine = n
                        buildChars(t, Array.isArray(m.char_times) ? m.char_times : [])
                        rollTo(p, t, n)
                    } else {
                        prevLine = p; lyric = t; nextLine = n
                        dPrev = p; dLyric = t; dNext = n
                    }
                    position = m.position || 0
                    lineStart = m.line_start || 0
                    duration = m.duration || 0
                    playing = !!m.playing
                    metaTime = Date.now()
                    lineElapsed = Math.max(0, position - lineStart)
                    var cv = m.cover || ""
                    var cvVer = m.cover_ver || 0
                    if (cv !== coverPath || cvVer !== coverVer) {
                        coverPath = cv
                        coverVer = cvVer
                        coverSource = cv ? "file://" + cv + "?v=" + cvVer : ""
                    }
                } catch(e) {}
            }
        }
        try { xhr.send() } catch(e) {}
    }

    // 低频率轮询 meta（本机文件，150ms 足够低）
    Timer { interval: 150; running: true; repeat: true; onTriggered: readMeta() }

    // 高频率播放推进：两次轮询之间按系统时间匀速推进，逐字/进度条连续无跳变
    Timer {
        id: advanceTimer
        interval: 33
        running: true
        repeat: true
        onTriggered: {
            if (root.playing) {
                var now = (Date.now() - root.metaTime) / 1000
                root.lineElapsed = Math.max(0, root.position - root.lineStart + now)
                if (root.duration > 0) {
                    root.progress = Math.min(1, (root.position + now) / root.duration)
                }
            } else {
                root.lineElapsed = Math.max(0, root.position - root.lineStart)
                if (root.duration > 0) {
                    root.progress = Math.min(1, root.position / root.duration)
                }
            }
        }
    }

    Item {
        id: view
        anchors.fill: parent
        clip: true

        RowLayout {
            id: mainRow
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing * 2

            // 封面：直接显示在 widget 上，高度略小于任务栏
            Item {
                id: coverItem
                Layout.preferredWidth: Math.max(28, root.height - 4)
                Layout.preferredHeight: Math.max(28, root.height - 4)
                visible: root.showCover && root.coverSource !== ""
                Image {
                    anchors.fill: parent
                    source: root.coverSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            Item {
                id: lyricArea
                Layout.fillWidth: true
                Layout.fillHeight: true

                Column {
                    id: lyricsColumn
                    anchors.fill: parent
                    spacing: 0
                    transform: Translate { id: roll; y: 0 }

                    PlasmaComponents3.Label {
                        text: root.dPrev; width: parent.width; clip: true
                        height: root.dm === 3 ? parent.height * 0.5 : (root.dm === 1 ? parent.height * 0.3 : 0)
                        font.pixelSize: root.fs; font.italic: root.fi
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.35)
                        elide: Text.ElideRight; maximumLineCount: 1; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        visible: root.dPrev !== "" && (root.dm === 1 || root.dm === 3)
                    }

                    // 当前行：卡拉 OK 逐字点亮（唱到的亮、未唱到的暗）；无字符时间时回退为整行
                    Item {
                        id: currentLine
                        width: parent.width
                        height: root.dm === 0 ? parent.height : (root.dm === 1 ? parent.height * 0.4 : parent.height * 0.5)
                        clip: true

                        PlasmaComponents3.Label {
                            id: plainLabel
                            anchors.fill: parent
                            text: root.dLyric
                            font.pixelSize: root.fs; font.weight: root.fw; font.italic: root.fi
                            color: Kirigami.Theme.textColor
                            elide: Text.ElideRight; maximumLineCount: 1; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            visible: !root.karaoke
                        }

                        // 卡拉 OK：单层逐字，每个字在其时间点前后 120ms 内平滑渐亮
                        Row {
                            id: karaokeRow
                            visible: root.karaoke
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            Repeater {
                                model: root.karaoke ? root.lyricChars.length : 0
                                delegate: Text {
                                    text: root.lyricChars[index]
                                    height: currentLine.height
                                    font.pixelSize: root.fs; font.weight: root.fw; font.italic: root.fi
                                    color: root.charColor(index)
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }

                    PlasmaComponents3.Label {
                        text: root.dNext; width: parent.width; clip: true
                        height: root.dm === 2 ? parent.height * 0.5 : (root.dm === 1 ? parent.height * 0.3 : 0)
                        font.pixelSize: root.fs; font.italic: root.fi
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.35)
                        elide: Text.ElideRight; maximumLineCount: 1; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        visible: root.dNext !== "" && (root.dm === 1 || root.dm === 2)
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width * (root.progress > 0 ? root.progress : 0)
                    height: 2
                    color: Kirigami.Theme.highlightColor
                    visible: root.sp && root.progress > 0
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                }
            }
        }
    }

    NumberAnimation {
        id: rollAnim
        target: roll
        property: "y"
        from: root.lineSlot()
        to: 0
        duration: 220
        easing.type: Easing.OutCubic
    }
}
