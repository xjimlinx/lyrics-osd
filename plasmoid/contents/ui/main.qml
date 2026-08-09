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

    // 歌曲信息（悬浮提示用）
    property string songTitle: ""
    property string songArtist: ""
    property real position: 0
    property real lineStart: 0

    // 卡拉 OK 逐字高亮
    property var lyricChars: []
    property var charTimes: []
    property bool karaoke: false
    property real lineElapsed: 0

    // 封面
    property string coverPath: ""
    property int coverVer: 0
    property string coverSource: ""

    // 悬浮提示：封面 + 歌名/歌手/进度（Plasma 内置 tooltip）
    toolTipMainText: root.songTitle !== "" ? root.songTitle : ""
    toolTipSubText: root.songArtist !== ""
        ? root.songArtist + (root.progress > 0 ? "  ·  " + Math.round(root.progress * 100) + "%" : "")
        : ""
    toolTipItem: Item {
        width: 160
        height: 160
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
                font.pixelSize: 48
                color: Kirigami.Theme.textColor
            }
        }
    }

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
                    var pr = m.progress || 0
                    if (t !== lyric) {
                        prevLine = p; lyric = t; nextLine = n
                        buildChars(t, Array.isArray(m.char_times) ? m.char_times : [])
                        rollTo(p, t, n)
                    } else {
                        prevLine = p; lyric = t; nextLine = n
                        dPrev = p; dLyric = t; dNext = n
                    }
                    progress = pr
                    songTitle = m.title || ""
                    songArtist = m.artist || ""
                    position = m.position || 0
                    lineStart = m.line_start || 0
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

    Timer { interval: 250; running: true; repeat: true; onTriggered: readMeta() }

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
                            Behavior on color { ColorAnimation { duration: 160 } }
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
