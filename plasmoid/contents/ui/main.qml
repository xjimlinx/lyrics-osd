import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
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

    // 歌曲信息（悬浮提示与逐字推进用）
    property string songTitle: ""
    property string songArtist: ""
    property real position: 0
    property real lineStart: 0
    property real duration: 0
    property bool playing: false
    property real metaTime: 0       // 最近一次 meta 读取的系统时间 (ms)

    // 卡拉 OK 逐字高亮
    property var lyricChars: []
    property var charTimes: []
    property bool karaoke: false
    property real lineElapsed: 0

    // 封面
    property string coverPath: ""
    property int coverVer: 0
    property string coverSource: ""

    // 悬浮提示状态
    property bool hovered: false
    property bool tipReady: false

    function lineSlot() {
        if (view.height <= 0) return 0
        if (root.dm === 0) return view.height
        if (root.dm === 1) return view.height * 0.4
        return view.height * 0.5
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
        // 只有字符时间戳与正文等长时才启用逐字；否则整行显示
        var chars = text.split("")
        lyricChars = chars
        if (times && times.length === chars.length) {
            charTimes = times
            karaoke = true
        } else {
            charTimes = []
            karaoke = false
        }
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
                    songTitle = m.title || ""
                    songArtist = m.artist || ""
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

    // 悬浮提示：显式控制 Plasma 底层 tooltip（比 PlasmoidItem 内置属性可靠）
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: {
            root.hovered = true
            tooltipDelay.start()
        }
        onExited: {
            root.hovered = false
            root.tipReady = false
            tooltipDelay.stop()
        }
    }

    Timer {
        id: tooltipDelay
        interval: 350
        onTriggered: {
            if (root.hovered) root.tipReady = true
        }
    }

    // 自定义悬浮弹窗：中心与 widget 中心对齐（高度居中），并限制在屏幕内
    PlasmaCore.Dialog {
        id: tipDialog
        location: PlasmaCore.Types.Floating
        flags: Qt.ToolTip
        hideOnWindowDeactivate: true
        visible: root.hovered && root.tipReady
                 && (root.songTitle !== "" || root.coverSource !== "")
        mainItem: tooltipContent
        x: {
            var pos = root.mapToGlobal(0, 0)
            var x0 = Math.round(pos.x + root.width / 2 - tooltipContent.width / 2)
            var s = root.availableScreenRect
            return Math.max(s.x, Math.min(x0, s.x + s.width - tooltipContent.width))
        }
        y: {
            var pos = root.mapToGlobal(0, 0)
            var y0 = Math.round(pos.y + root.height / 2 - tooltipContent.height / 2)
            var s = root.availableScreenRect
            return Math.max(s.y, Math.min(y0, s.y + s.height - tooltipContent.height))
        }
    }

    // tooltip 内容：封面 + 歌名/歌手/进度
    Item {
        id: tooltipContent
        width: 190
        height: Math.max(32, root.height)

        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing * 2

            Item {
                // 封面高度略小于任务栏高度：跟随 widget 高度
                Layout.preferredWidth: Math.max(32, root.height)
                Layout.preferredHeight: Math.max(32, root.height)
                Image {
                    anchors.fill: parent
                    source: root.coverSource
                    fillMode: Image.PreserveAspectFit
                    visible: root.coverSource !== ""
                }
                Rectangle {
                    anchors.fill: parent
                    color: Kirigami.Theme.backgroundColor
                    visible: root.coverSource === ""
                    PlasmaComponents3.Label {
                        anchors.centerIn: parent
                        text: "♪"
                        font.pixelSize: Math.max(16, root.height * 0.4)
                        color: Kirigami.Theme.textColor
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: root.songTitle !== "" ? root.songTitle : "♪"
                    font.bold: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: root.songArtist
                    opacity: 0.75
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize - 1
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text !== ""
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    visible: root.duration > 0
                    PlasmaComponents3.ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        value: root.progress
                    }
                    PlasmaComponents3.Label {
                        text: root.duration > 0
                            ? Math.floor(root.progress * root.duration / 60) + ":" +
                              String(Math.floor(root.progress * root.duration % 60)).padStart(2, "0") +
                              " / " +
                              Math.floor(root.duration / 60) + ":" +
                              String(Math.floor(root.duration % 60)).padStart(2, "0")
                            : ""
                        opacity: 0.75
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize - 2
                    }
                }
            }
        }
    }

    Item {
        id: view
        anchors.fill: parent
        clip: true

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

            // 当前行：卡拉 OK 逐字点亮；无字符时间时回退为整行
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

                Row {
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
                            color: root.lineElapsed >= root.charTimes[index]
                                   ? Kirigami.Theme.highlightColor
                                   : Kirigami.Theme.textColor
                            verticalAlignment: Text.AlignVCenter
                            Behavior on color { ColorAnimation { duration: 140 } }
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
