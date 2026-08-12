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
    // 显示行数与歌词变体合并为一个设置：
    // 0-4 单/双行内容（dm=0），5=三行原词（dm=1），6=两行原词当前+下一行（dm=2）
    property int dm: root.variant === 6 ? 2 : (root.variant === 5 ? 1 : 0)
    property int fs: Plasmoid.configuration.fontPixelSize
    property int variant: Plasmoid.configuration.lyricsVariant
    property int fw: Plasmoid.configuration.fontBold ? Font.Bold : Font.Normal
    property bool fi: Plasmoid.configuration.fontItalic
    property bool sp: Plasmoid.configuration.showProgress
    property bool karaokeMode: Plasmoid.configuration.karaokeMode
    property bool showCover: Plasmoid.configuration.showCover
    property string tlLyric: ""      // 当前行翻译
    property string tlPrev: ""
    property string tlNext: ""
    property string romLyric: ""     // 当前行音译
    property string romPrev: ""
    property string romNext: ""

    // 歌曲信息（封面与逐字推进用）
    property real position: 0
    property real lineStart: 0
    property real lineEnd: 0
    property real duration: 0
    property bool playing: false
    property real metaTime: 0       // 最近一次 meta 读取的系统时间 (ms)

    // 卡拉 OK 逐字高亮
    property var lyricChars: []
    property var charTimes: []
    property var charDurs: []
    property bool karaoke: root.karaokeMode
                          && root.charTimes.length === root.lyricChars.length
                          && root.lyricChars.length > 0
    property real lineElapsed: 0

    // 跑马灯：单句过长时水平滚动 + 边缘淡出（Apple 顶栏/酷狗同款思路）
    property bool marqueeOn: false
    property real marqueeOffset: 0
    property real marqueeViewW: 0
    property string marqueeText: ""

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

    function rowFont(frac) {
        // 按行高自动缩小字号：min(设置字号, 行高×0.88)，多行时不会互相挤压
        return Math.max(8, Math.min(root.fs, Math.floor(root.height * frac * 0.88)))
    }

    function currentFrac() {
        // 当前行在 widget 高度中的占比：三行 0.4，两行 0.5，单行/双行内容 1
        if (root.dm === 1) return 0.4
        if (root.dm === 2 || root.dm === 3) return 0.5
        return root.subVisible() ? 0.5 : 1
    }

    function measureMarquee() {
        // 文本自然宽度超过可视宽度时开启跑马灯；未变化则保持现状
        var viewW = currentLine.width
        if (viewW <= 0) return
        var tw = Math.max(plainLabel.implicitWidth, textLayer.implicitWidth)
        var should = tw > viewW + 4
        if (should && root.marqueeOn && root.marqueeText === root.dLyric && root.marqueeViewW === viewW) return
        root.marqueeText = root.dLyric
        root.marqueeViewW = viewW
        if (should) {
            var dist = tw - viewW + 30
            var dur = Math.max(3000, dist / 0.045)
            root.marqueeOn = true
            marqueeSeq.stop()
            marqueeAnim.from = 0
            marqueeAnim.to = -dist
            marqueeAnim.duration = dur
            marqueeBackAnim.from = -dist
            marqueeBackAnim.to = 0
            marqueeBackAnim.duration = dur
            root.marqueeOffset = 0
            marqueeSeq.restart()
        } else {
            marqueeSeq.stop()
            root.marqueeOn = false
            root.marqueeOffset = 0
        }
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
        // 只有字符时间戳与正文等长时才逐字；karaoke 为绑定，配置改动即时生效。
        // times 为相对行首的起始时间；durs 为该字持续时长，缺失时按后一字时间差派生。
        var durs = arguments.length > 2 ? arguments[2] : null
        lyricChars = text.split("")
        var ok = Array.isArray(times) && times.length === lyricChars.length
        charTimes = ok ? times : []
        if (ok) {
            if (Array.isArray(durs) && durs.length === lyricChars.length) {
                charDurs = durs
            } else {
                var dd = []
                for (var i = 0; i < times.length - 1; i++) dd.push(Math.max(0.03, times[i + 1] - times[i]))
                dd.push(0.15)
                charDurs = dd
            }
            // KRC 逐字时间常早于下一行开始：按行时长适度整体拉伸扫光，
            // 避免扫光提前结束后整行长时间全亮（限制拉伸幅度，极端间隔保持原样）
            if (root.lineEnd > root.lineStart && charTimes.length > 0) {
                var lineDur = root.lineEnd - root.lineStart
                var lastEnd = charTimes[charTimes.length - 1] + charDurs[charDurs.length - 1]
                var factor = lineDur / lastEnd
                if (factor > 1.12 && factor < 2.2) {
                    for (var k = 0; k < charTimes.length; k++) {
                        charTimes[k] = Math.round(charTimes[k] * factor * 1000) / 1000
                        charDurs[k] = Math.round(charDurs[k] * factor * 1000) / 1000
                    }
                }
            }
        } else {
            charDurs = []
        }
    }

    function dimColor() {
        var base = Kirigami.Theme.textColor
        return Qt.rgba(base.r, base.g, base.b, 0.42)
    }

    function charFill(i) {
        // 每个字的扫光进度：按它自己的起止时间 0→1 连续填充（0=暗，1=高亮）
        if (!root.karaoke || i >= root.charTimes.length) return 1
        var d = root.charDurs[i] || 0.15
        var f = (root.lineElapsed - root.charTimes[i]) / d
        return Math.max(0, Math.min(1, f))
    }

    function lineFill() {
        // 整行扫光位置：当前字序号 + 字内填充 → 0..1 连续值。
        // 边缘正好落在正在唱的字上（一半亮一半暗），按每字的实际时长推进
        if (!root.karaoke || root.charTimes.length === 0) return 0
        var i = 0
        while (i < root.charTimes.length - 1 && root.lineElapsed >= root.charTimes[i + 1]) i++
        var f = root.charFill(i)
        return (i + f) / root.charTimes.length
    }

    function subLyricText() {
        // 双行模式的副行：变体 3=翻译，4=音译
        if (root.variant === 3) return root.tlLyric
        if (root.variant === 4) return root.romLyric
        return ""
    }

    function subVisible() {
        return (root.variant === 3 || root.variant === 4) && subLyricText() !== ""
    }

    function variantText(base, tl, rom) {
        // 单行模式：变体 1=翻译，2=音译；缺失时回退原词
        if (root.variant === 1 && tl) return tl
        if (root.variant === 2 && rom) return rom
        return base
    }

    function mapCharTimes(origTimes, origText, newText) {
        // 翻译/音译没有逐字时间戳，把原词的逐字时间按字符数比例映射过去，
        // 让卡拉 OK 高亮在翻译文本上同样跟唱（逐词对齐为近似值）。
        var n = newText.length
        var m = origText.length
        var out = []
        if (n === 0 || m === 0) return out
        if (!Array.isArray(origTimes) || origTimes.length !== m) return out
        for (var i = 0; i < n; i++) {
            var j = Math.round(i * (m - 1) / Math.max(1, n - 1))
            out.push(origTimes[j])
        }
        return out
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
                    tlLyric = m.tl_line || ""
                    tlPrev = m.tl_prev || ""
                    tlNext = m.tl_next || ""
                    romLyric = m.rom_line || ""
                    romPrev = m.rom_prev || ""
                    romNext = m.rom_next || ""
                    lineStart = m.line_start || 0
                    lineEnd = m.line_end || 0
                    var origChars = Array.isArray(m.char_times) ? m.char_times : []
                    var origDurs = Array.isArray(m.char_durs) ? m.char_durs : []
                    var disp = variantText(t, tlLyric, romLyric)
                    var dispP = variantText(p, tlPrev, romPrev)
                    var dispN = variantText(n, tlNext, romNext)
                    var charsText = t
                    var charsTimes = origChars
                    var charsDurs = origDurs
                    if (root.variant === 1 && tlLyric) {
                        charsText = tlLyric
                        charsTimes = mapCharTimes(origChars, t, tlLyric)
                        charsDurs = null
                    } else if (root.variant === 2 && romLyric) {
                        charsText = romLyric
                        charsTimes = mapCharTimes(origChars, t, romLyric)
                        charsDurs = null
                    }
                    if (t !== lyric) {
                        prevLine = p; lyric = t; nextLine = n
                        buildChars(charsText, charsTimes, charsDurs)
                        rollTo(dispP, disp, dispN)
                    } else {
                        prevLine = p; lyric = t; nextLine = n
                        dPrev = dispP; dLyric = disp; dNext = dispN
                        if (root.variant === 1 || root.variant === 2) {
                            buildChars(charsText, charsTimes, charsDurs)
                        }
                    }
                    position = m.position || 0
                    duration = m.duration || 0
                    playing = !!m.playing
                    metaTime = Date.now()
                    if (t === lyric) {
                        // seek 回退检测：position 明显小于当前推进值时允许重置
                        var baseline = Math.max(0, position - lineStart)
                        if (baseline < lineElapsed - 0.8) {
                            lineElapsed = baseline
                        }
                    } else {
                        lineElapsed = 0   // 新行从 0 开始，由推进器推进
                    }
                    var cv = m.cover || ""
                    var cvVer = m.cover_ver || 0
                    if (cv !== coverPath || cvVer !== coverVer) {
                        coverPath = cv
                        coverVer = cvVer
                        coverSource = cv ? "file://" + cv + "?v=" + cvVer : ""
                    }
                    measureMarquee()
                } catch(e) {}
            }
        }
        try { xhr.send() } catch(e) {}
    }

    // 轮询 meta（本机文件，60ms 几乎无开销，换行更跟手）
    Timer { interval: 60; running: true; repeat: true; onTriggered: readMeta() }

    // 高频率播放推进：两次轮询之间按系统时间匀速推进，逐字/进度条连续无跳变
    Timer {
        id: advanceTimer
        interval: 33
        running: true
        repeat: true
        onTriggered: {
            if (root.playing) {
                var now = (Date.now() - root.metaTime) / 1000
                // 单调推进：轮询的 position 可能滞后，只进不退，避免字反复横跳
                root.lineElapsed = Math.max(root.lineElapsed, Math.max(0, root.position - root.lineStart + now))
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
                        font.pixelSize: root.dm === 1 ? root.rowFont(0.3) : (root.dm === 3 ? root.rowFont(0.5) : root.fs); font.italic: root.fi
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
                        onWidthChanged: measureMarquee()
                        // 跑马灯时给整行加边缘渐变淡出遮罩（Apple 顶栏歌词风格）
                        layer.enabled: root.marqueeOn
                        layer.smooth: true
                        layer.effect: ShaderEffect {
                            property real fadePx: 14
                            property real viewW: currentLine.width > 1 ? currentLine.width : 1
                            fragmentShader: "shaders/edgefade.frag.qsb"
                        }

                        // 用锚点定位而非 Column：主行隐藏（卡拉OK接管）时副行仍固定在底部，互不重叠
                        Item {
                            anchors.fill: parent
                            PlasmaComponents3.Label {
                                id: plainLabel
                                width: implicitWidth
                                x: root.marqueeOn ? root.marqueeOffset : Math.max(0, (parent.width - width) / 2)
                                anchors.top: parent.top
                                height: root.subVisible() ? parent.height * 0.5 : parent.height
                                text: root.dLyric
                                font.pixelSize: root.rowFont(root.currentFrac())
                                font.weight: root.fw; font.italic: root.fi
                                color: Kirigami.Theme.textColor
                                elide: Text.ElideNone; maximumLineCount: 1; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter
                                visible: !root.karaoke
                            }
                            // 双行模式：原词在上、翻译/音译在下，两行等高
                            PlasmaComponents3.Label {
                                id: subLabel
                                width: parent.width
                                anchors.bottom: parent.bottom
                                height: root.subVisible() ? parent.height * 0.5 : 0
                                visible: root.subVisible()
                                text: root.subLyricText()
                                font.pixelSize: root.rowFont(0.5)
                                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.55)
                                elide: Text.ElideRight; maximumLineCount: 1; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // 卡拉 OK：ShaderEffect 扫光——按 x 坐标把高亮/暗色做平滑渐变混合，
                        // 边缘 12px 柔和过渡 + 微光，正唱到的字一半亮一半暗且无生硬接缝
                        Item {
                            id: karaokeRow
                            visible: root.karaoke
                            x: root.marqueeOn ? root.marqueeOffset : Math.max(0, (currentLine.width - width) / 2)
                            anchors.top: parent.top
                            width: textLayer.implicitWidth
                            y: 0
                            height: root.subVisible() ? parent.height * 0.5 : parent.height

                            Text {
                                id: textLayer
                                anchors.fill: parent
                                text: root.dLyric
                                font.pixelSize: root.rowFont(root.currentFrac())
                                font.weight: root.fw; font.italic: root.fi
                                color: "white"   // 实际颜色由 shader 输出，这里只提供字形 alpha
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                layer.enabled: true
                                layer.smooth: true
                                layer.effect: ShaderEffect {
                                    property real progress: root.lineFill()
                                    property color dimColor: root.dimColor()
                                    property color hlColor: Kirigami.Theme.highlightColor
                                    property real softPx: 12
                                    property real widthPx: karaokeRow.width > 1 ? karaokeRow.width : 1
                                    fragmentShader: "shaders/karaoke.frag.qsb"
                                }
                            }
                        }
                    }

                    PlasmaComponents3.Label {
                        text: root.dNext; width: parent.width; clip: true
                        height: root.dm === 2 ? parent.height * 0.5 : (root.dm === 1 ? parent.height * 0.3 : 0)
                        font.pixelSize: root.dm === 1 ? root.rowFont(0.3) : (root.dm === 2 ? root.rowFont(0.5) : root.fs); font.italic: root.fi
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
        duration: 150
        easing.type: Easing.OutCubic
    }

    // 跑马灯：乒乓式——正向滚到行尾 → 停顿 → 反向滚回行首 → 停顿，无跳变
    SequentialAnimation {
        id: marqueeSeq
        running: false
        loops: Animation.Infinite
        NumberAnimation {
            id: marqueeAnim
            target: root
            property: "marqueeOffset"
            from: 0
            to: -200
            duration: 4000
            easing.type: Easing.Linear
        }
        PauseAnimation { duration: 1000 }
        NumberAnimation {
            id: marqueeBackAnim
            target: root
            property: "marqueeOffset"
            from: -200
            to: 0
            duration: 4000
            easing.type: Easing.Linear
        }
        PauseAnimation { duration: 800 }
    }
}
