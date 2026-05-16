import QtQuick
import QtQuick.Layouts
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

    Kirigami.FormLayout {

        QQC2.Label {
            text: "刷新"
            font.bold: true
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
            topPadding: 8; bottomPadding: 4
        }

        QQC2.SpinBox {
            id: refreshSpinBox
            Kirigami.FormData.label: "刷新间隔 (ms)"
            from: 50; to: 5000; stepSize: 50
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label {
            text: "字体"
            font.bold: true
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
            topPadding: 8; bottomPadding: 4
        }

        QQC2.SpinBox {
            id: fontSizeSpinBox
            Kirigami.FormData.label: "字号"
            from: 8; to: 72
        }

        QQC2.CheckBox {
            id: boldCheckBox
            Kirigami.FormData.label: "加粗"
        }

        QQC2.CheckBox {
            id: italicCheckBox
            Kirigami.FormData.label: "斜体"
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label {
            text: "尺寸"
            font.bold: true
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
            topPadding: 8; bottomPadding: 4
        }

        QQC2.SpinBox {
            id: widthSpinBox
            Kirigami.FormData.label: "宽度"
            from: 100; to: 2000; stepSize: 10
        }

        QQC2.SpinBox {
            id: heightSpinBox
            Kirigami.FormData.label: "高度"
            from: 16; to: 200
        }
    }
}
