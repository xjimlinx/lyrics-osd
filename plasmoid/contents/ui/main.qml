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
    property int dm: 0
    property int fs: Plasmoid.configuration.fontPixelSize
    property int fw: Plasmoid.configuration.fontBold ? Font.Bold : Font.Normal
    property bool sp: Plasmoid.configuration.showProgress

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
                        rollTo(p, t, n)
                    } else {
                        prevLine = p; lyric = t; nextLine = n
                        dPrev = p; dLyric = t; dNext = n
                    }
                    progress = pr
                } catch(e) {}
            }
        }
        try { xhr.send() } catch(e) {}
    }

    Timer { interval: 250; running: true; repeat: true; onTriggered: readMeta() }
    Timer { interval: 500; running: true; repeat: true; onTriggered: { dm = Number(Plasmoid.configuration.displayMode); fs = Number(Plasmoid.configuration.fontPixelSize); fw = Plasmoid.configuration.fontBold ? Font.Bold : Font.Normal; sp = Plasmoid.configuration.showProgress } }

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
                font.pixelSize: root.fs; font.italic: Plasmoid.configuration.fontItalic
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.35)
                elide: Text.ElideRight; maximumLineCount: 1; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                visible: root.dPrev !== "" && (root.dm === 1 || root.dm === 3)
            }
            PlasmaComponents3.Label {
                text: root.dLyric; width: parent.width; clip: true
                height: root.dm === 0 ? parent.height : (root.dm === 1 ? parent.height * 0.4 : parent.height * 0.5)
                font.pixelSize: root.fs; font.weight: root.fw; font.italic: Plasmoid.configuration.fontItalic
                color: Kirigami.Theme.textColor
                elide: Text.ElideRight; maximumLineCount: 1; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
            PlasmaComponents3.Label {
                text: root.dNext; width: parent.width; clip: true
                height: root.dm === 2 ? parent.height * 0.5 : (root.dm === 1 ? parent.height * 0.3 : 0)
                font.pixelSize: root.fs; font.italic: Plasmoid.configuration.fontItalic
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
