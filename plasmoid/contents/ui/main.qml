import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation
    Layout.preferredWidth: 420
    Layout.preferredHeight: root.dm === 0 ? Kirigami.Units.gridUnit * 2 : Kirigami.Units.gridUnit * 3

    property string lyric: "♪"
    property string prevLine: ""
    property string nextLine: ""
    property real progress: 0
    property int dm: 0
    property int fs: Plasmoid.configuration.fontPixelSize
    property int fw: Plasmoid.configuration.fontBold ? Font.Bold : Font.Normal

    onDmChanged: console.log("dm =", dm)

    function readMeta() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/lyrics-meta.json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try {
                    var m = JSON.parse(xhr.responseText)
                    var t = m.current_line || m.title || ""
                    if (m.artist && t === m.title) t = m.artist + " - " + t
                    if (t && t !== lyric) { lyric = t }
                    prevLine = m.prev_line || ""
                    nextLine = m.next_line || ""
                    progress = m.progress || 0
                } catch(e) {}
            }
        }
        try { xhr.send() } catch(e) {}
    }

    Timer { interval: 250; running: true; repeat: true; onTriggered: readMeta() }
    Timer { interval: 500; running: true; repeat: true; onTriggered: { dm = Number(Plasmoid.configuration.displayMode); fs = Number(Plasmoid.configuration.fontPixelSize); fw = Plasmoid.configuration.fontBold ? Font.Bold : Font.Normal } }

    Item { anchors.fill: parent; clip: true
        Column { anchors.fill: parent; spacing: 0

            PlasmaComponents3.Label {
                text: root.prevLine; width: parent.width; clip: true
                height: root.dm === 3 ? parent.height * 0.48 : (root.dm === 1 ? parent.height * 0.28 : 0)
                font.pixelSize: root.fs; font.italic: Plasmoid.configuration.fontItalic
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.35)
                elide: Text.ElideRight; maximumLineCount: 1; horizontalAlignment: Text.AlignHCenter
                visible: root.prevLine !== "" && (root.dm === 1 || root.dm === 3)
            }

            PlasmaComponents3.Label {
                text: root.lyric; width: parent.width; clip: true
                height: root.dm === 0 ? parent.height : (root.dm === 1 ? parent.height * 0.38 : parent.height * 0.48)
                font.pixelSize: root.fs; font.weight: root.fw; font.italic: Plasmoid.configuration.fontItalic
                color: Kirigami.Theme.textColor
                elide: Text.ElideRight; maximumLineCount: 1; horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents3.Label {
                text: root.nextLine; width: parent.width; clip: true
                height: root.dm === 2 ? parent.height * 0.48 : (root.dm === 1 ? parent.height * 0.28 : 0)
                font.pixelSize: root.fs; font.italic: Plasmoid.configuration.fontItalic
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.35)
                elide: Text.ElideRight; maximumLineCount: 1; horizontalAlignment: Text.AlignHCenter
                visible: root.nextLine !== "" && (root.dm === 1 || root.dm === 2)
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width * (root.progress > 0 ? root.progress : 0); height: 2
            color: Kirigami.Theme.highlightColor; visible: root.progress > 0
        }
    }
}
