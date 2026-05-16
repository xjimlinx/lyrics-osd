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

    readonly property string labelColor: Plasmoid.configuration.lyricColor || Kirigami.Theme.textColor
    readonly property int labelSize: Plasmoid.configuration.fontPixelSize

    function fetchLyric() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///tmp/lyrics-current.txt")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var t = xhr.responseText.trim()
                if (t) lyric = t
            }
        }
        try { xhr.send() } catch(e) {}
    }

    Timer {
        interval: Plasmoid.configuration.refreshInterval
        running: true
        repeat: true
        onTriggered: fetchLyric()
    }

    PlasmaComponents3.Label {
        anchors.fill: parent
        text: lyric
        font.pixelSize: labelSize
        font.bold: Plasmoid.configuration.fontBold
        font.italic: Plasmoid.configuration.fontItalic
        color: labelColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    Component.onCompleted: fetchLyric()
}
