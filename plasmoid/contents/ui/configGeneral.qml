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
    property alias cfg_lyricsSource: sourceCombo.currentIndex
    property alias cfg_lyricsVariant: variantCombo.currentIndex
    property alias cfg_playerType: playerCombo.currentIndex
    property alias cfg_proxyUrl: proxyField.text
    property alias cfg_showProgress: progressCheck.checked
    property alias cfg_karaokeMode: karaokeCheck.checked
    property alias cfg_showCover: coverCheck.checked
    // clearCache 是动作型配置（按钮直接写入），仅需接收框架的初始值，避免告警
    property bool cfg_clearCache: false

    Kirigami.FormLayout {
        QQC2.Label { text: "刷新"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.SpinBox {
            id: refreshSpinBox; Kirigami.FormData.label: "刷新间隔 (ms)"; from: 50; to: 5000; stepSize: 50
        }
        QQC2.Label {
            text: "歌词与播放进度的刷新频率。越小越跟手，但更耗 CPU，一般 200-500ms 即可。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "播放器"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.ComboBox {
            id: playerCombo; Kirigami.FormData.label: "播放器"
            model: ["QQ Music", "网易云音乐", "Spotify", "MoeKoeMusic"]
            Component.onCompleted: if (typeof Plasmoid !== "undefined") currentIndex = Plasmoid.configuration.playerType
        }
        QQC2.Label {
            text: "选择要同步歌词的音乐播放器。MoeKoeMusic 需先在音乐软件内开启 API 服务（端口 6520）。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "歌词源"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.ComboBox {
            id: sourceCombo; Kirigami.FormData.label: "歌词来源"
            model: ["全部 (并行)", "QQ Music 原生", "仅 lrclib.net", "仅 网易云音乐", "优先 lrclib", "优先 网易云"]
            Component.onCompleted: if (typeof Plasmoid !== "undefined") currentIndex = Plasmoid.configuration.lyricsSource
        }
        QQC2.Label {
            text: "全部（并行）：多来源同时查询，取先返回的结果。\nQQ Music 原生：仅用播放器提供的歌词。\n仅 lrclib / 仅网易云：只从对应在线源获取。\n优先 lrclib / 优先网易云：在线源优先，缺失时回退播放器原生歌词。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        QQC2.ComboBox {
            id: variantCombo; Kirigami.FormData.label: "歌词变体"
            model: ["单行·原词", "单行·翻译", "单行·音译",
                    "两行·原词 + 翻译", "两行·原词 + 音译", "三行·原词（上下句）"]
            Component.onCompleted: if (typeof Plasmoid !== "undefined") currentIndex = Plasmoid.configuration.lyricsVariant
        }
        QQC2.Label {
            text: "单行：只显示当前行。两行：原词在上、翻译/音译在下，两行等高。三行：当前行居中，上下各显示一行原词。翻译/音译无数据时自动回退原词；卡拉OK扫光在原词行上，单行翻译/音译时按原词时间比例映射。字号会按行高自动缩小，多行时不会互相挤压。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "字体"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.SpinBox {
            id: fontSizeSpinBox; Kirigami.FormData.label: "字号"; from: 8; to: 72
        }
        QQC2.Label {
            text: "歌词文字大小（像素）。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        QQC2.CheckBox {
            id: boldCheckBox; Kirigami.FormData.label: "加粗"
        }
        QQC2.Label {
            text: "歌词文字加粗显示。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        QQC2.CheckBox {
            id: italicCheckBox; Kirigami.FormData.label: "斜体"
        }
        QQC2.Label {
            text: "歌词文字斜体显示。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "尺寸"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.SpinBox {
            id: widthSpinBox; Kirigami.FormData.label: "宽度"; from: 100; to: 2000; stepSize: 10
        }
        QQC2.Label {
            text: "Widget 在面板上占用的宽度（像素）。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        QQC2.SpinBox {
            id: heightSpinBox; Kirigami.FormData.label: "高度"; from: 16; to: 200
        }
        QQC2.Label {
            text: "Widget 在面板上占用的高度（像素）。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: progressCheck; Kirigami.FormData.label: "进度条"
            text: "显示播放进度条"
        }
        QQC2.Label {
            text: "在歌词旁边显示当前播放进度条。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        QQC2.CheckBox {
            id: karaokeCheck; Kirigami.FormData.label: "卡拉 OK"
            text: "逐字点亮当前行歌词"
        }
        QQC2.Label {
            text: "唱到的字高亮、未唱到的字变暗，逐字点亮。需要 MoeKoeMusic 的 KRC 歌词，其他歌词源自动整行显示。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        QQC2.CheckBox {
            id: coverCheck; Kirigami.FormData.label: "封面"
            text: "显示专辑封面"
        }
        QQC2.Label {
            text: "在歌词左侧显示当前歌曲的专辑封面，无封面时自动隐藏。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "网络"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.TextField {
            id: proxyField; Kirigami.FormData.label: "HTTP 代理"
            placeholderText: "http://127.0.0.1:7890"
        }
        QQC2.Label {
            text: "访问在线歌词源（lrclib / 网易云）时使用的 HTTP 代理，格式如 http://127.0.0.1:7890，留空则不使用。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label { text: "缓存"; font.bold: true; topPadding: 8; bottomPadding: 4 }
        QQC2.Button {
            text: "清空歌词缓存"; icon.name: "edit-clear"
            onClicked: Plasmoid.configuration.clearCache = true
        }
        QQC2.Label {
            text: "删除已缓存的歌词数据，下次播放时重新获取。"
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            bottomPadding: 6
            Layout.fillWidth: true
        }
    }
}
