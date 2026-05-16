import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_refreshInterval: refreshSpinBox.value
    property alias cfg_fontPixelSize: fontSizeSpinBox.value
    property alias cfg_fontBold: boldCheckBox.checked
    property alias cfg_fontItalic: italicCheckBox.checked
    property alias cfg_widgetWidth: widthSpinBox.value
    property alias cfg_widgetHeight: heightSpinBox.value
    property alias cfg_lyricsSource: sourceCombo.currentIndex
    property alias cfg_playerType: playerCombo.currentIndex
    property alias cfg_displayMode: displayModeCombo.currentIndex
    property alias cfg_proxyUrl: proxyField.text

    Kirigami.FormLayout {
        QQC2.Label { text: "刷新"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.SpinBox { id: refreshSpinBox; Kirigami.FormData.label: "刷新间隔 (ms)"; from: 50; to: 5000; stepSize: 50 }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "播放器"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.ComboBox {
            id: playerCombo; Kirigami.FormData.label: "播放器"
            model: ["QQ Music", "网易云音乐", "Spotify"]
            Component.onCompleted: currentIndex = Plasmoid.configuration.playerType
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "歌词源"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.ComboBox {
            id: sourceCombo; Kirigami.FormData.label: "歌词来源"
            model: ["全部 (并行)", "QQ Music 原生", "仅 lrclib.net", "仅 网易云音乐", "优先 lrclib", "优先 网易云"]
            Component.onCompleted: currentIndex = Plasmoid.configuration.lyricsSource
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "字体"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.SpinBox { id: fontSizeSpinBox; Kirigami.FormData.label: "字号"; from: 8; to: 72 }
        QQC2.CheckBox { id: boldCheckBox; Kirigami.FormData.label: "加粗" }
        QQC2.CheckBox { id: italicCheckBox; Kirigami.FormData.label: "斜体" }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "尺寸"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.SpinBox { id: widthSpinBox; Kirigami.FormData.label: "宽度"; from: 100; to: 2000; stepSize: 10 }
        QQC2.SpinBox { id: heightSpinBox; Kirigami.FormData.label: "高度"; from: 16; to: 200 }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "显示"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.ComboBox {
            id: displayModeCombo; Kirigami.FormData.label: "显示模式"
            model: ["单行歌词", "三行歌词+进度条", "两行·当前在上", "两行·当前在下"]
            Component.onCompleted: currentIndex = Number(Plasmoid.configuration.displayMode)
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "网络"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.TextField {
            id: proxyField; Kirigami.FormData.label: "HTTP 代理"
            placeholderText: "http://127.0.0.1:7890"
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "缓存"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.Button { text: "清空歌词缓存"; icon.name: "edit-clear"; onClicked: Plasmoid.configuration.clearCache = true }
    }
}
