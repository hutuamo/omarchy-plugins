import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "hutuamo.barstats"

  readonly property string scriptPath: Quickshell.env("HOME") + "/.config/omarchy/plugins/hutuamo.barstats/cpu-temp.sh"

  property int cpu: 0
  property int memPercent: 0
  property real memUsedGb: 0
  property real memTotalGb: 0
  property int temp: 0
  property bool hasTemp: false

  // 显示开关，持久化在 shell.json 的条目里（缺省全开）
  readonly property bool showCpu: setting("showCpu", true)
  readonly property bool showMem: setting("showMem", true)
  readonly property bool showTemp: setting("showTemp", true)
  readonly property int enabledCount: (showCpu ? 1 : 0) + (showMem ? 1 : 0) + (showTemp ? 1 : 0)

  // 最少保留一项开启：关掉最后一个开着的项时直接忽略
  function toggleItem(key) {
    var current = key === "showCpu" ? showCpu : key === "showMem" ? showMem : showTemp
    if (current && enabledCount <= 1) return

    var entry = { id: root.moduleName }
    for (var k in root.settings) if (k !== "id") entry[k] = root.settings[k]
    entry[key] = !current

    // 先本地生效让开关立即响应，写回 shell.json 后 bar 会回填同样的值
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  readonly property color fg: root.bar ? root.bar.barForeground : Commons.Color.popups.text
  readonly property string labelFont: root.bar ? root.bar.fontFamily : Style.font.family

  readonly property string compactText: {
    var parts = []
    if (showCpu) parts.push(root.cpu + "%")
    if (showMem) parts.push(root.memPercent + "%")
    if (showTemp) parts.push(root.hasTemp ? root.temp + "°C" : "--°C")
    return parts.join(" ")
  }

  function update(raw) {
    try {
      var data = JSON.parse(String(raw).trim())
      if (data.cpu !== undefined) root.cpu = data.cpu
      if (data.mem_percent !== undefined) root.memPercent = data.mem_percent
      if (data.mem_used_gb !== undefined) root.memUsedGb = data.mem_used_gb
      if (data.mem_total_gb !== undefined) root.memTotalGb = data.mem_total_gb
      if (data.temp !== undefined && data.temp !== null) {
        root.temp = data.temp
        root.hasTemp = true
      } else {
        root.hasTemp = false
      }
    } catch (e) {}
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: probe
    command: [root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.update(text)
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!probe.running) probe.running = true
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.compactText
    fontSize: Style.font.caption
    tooltipText: ""
  }

  property bool popupOpen: false

  HoverHandler {
    id: hoverHandler
    onHoveredChanged: {
      if (hovered) {
        root.popupOpen = true
        closeTimer.stop()
      } else {
        closeTimer.restart()
      }
    }
  }

  Timer {
    id: closeTimer
    interval: 300
    repeat: false
    onTriggered: root.popupOpen = false
  }

  PopupWindow {
    id: detailPopup
    visible: root.popupOpen
    color: "transparent"
    implicitWidth: Math.ceil(card.implicitWidth)
    implicitHeight: Math.ceil(card.implicitHeight)

    anchor {
      window: button.QsWindow.window
      adjustment: PopupAdjustment.Slide
      edges: Edges.Top | Edges.Left
      gravity: Edges.Bottom | Edges.Right
      rect.width: 1
      rect.height: 1
      onAnchoring: {
        var popupW = detailPopup.implicitWidth
        var popupH = detailPopup.implicitHeight
        var localX = button.width / 2 - popupW / 2
        var localY = button.height + 6
        if (root.bar && root.bar.position === "bottom") localY = -popupH - 6
        var win = button.QsWindow.window
        if (!win) return
        var point = win.contentItem.mapFromItem(button, localX, localY)
        anchor.rect.x = Math.round(point.x)
        anchor.rect.y = Math.round(point.y)
      }
    }

    BorderSurface {
      id: card
      color: Commons.Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Commons.Color.popups.border, Math.max(1, Style.space(2)))
      radius: Style.cornerRadius
      padding: Style.spacing.popupPadding

      implicitWidth: content.implicitWidth + contentLeftInset + contentRightInset
      implicitHeight: content.implicitHeight + contentTopInset + contentBottomInset

      HoverHandler {
        onHoveredChanged: {
          if (hovered) {
            root.popupOpen = true
            closeTimer.stop()
          } else {
            closeTimer.restart()
          }
        }
      }

      Column {
        id: content
        x: card.contentLeftInset
        y: card.contentTopInset
        spacing: Style.space(16)

        // ---------- 头部：图标 + 标题 + 副标题 ----------
        Row {
          spacing: Style.space(12)

          Text {
            text: ""
            color: root.fg
            font.family: root.labelFont
            font.pixelSize: Style.font.displayLarge
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            spacing: Style.space(2)
            anchors.verticalCenter: parent.verticalCenter

            Text {
              text: "barstats"
              color: root.fg
              font.family: root.labelFont
              font.pixelSize: Style.font.heading
              font.bold: true
            }
            Text {
              text: "状态栏显示项设置"
              color: Qt.darker(root.fg, 1.6)
              font.family: root.labelFont
              font.pixelSize: Style.font.caption
              font.letterSpacing: 2
            }
          }
        }

        PanelSeparator {
          width: Style.space(280)
          foreground: root.fg
        }

        // ---------- 类目开关行 ----------
        StatRow {
          glyph: "󰻠"
          label: "CPU"
          value: root.cpu + "%"
          checked: root.showCpu
          onToggled: root.toggleItem("showCpu")
        }

        StatRow {
          glyph: "󰍛"
          label: "内存"
          value: root.memUsedGb.toFixed(1) + " / " + root.memTotalGb.toFixed(1) + " GB"
          checked: root.showMem
          onToggled: root.toggleItem("showMem")
        }

        StatRow {
          glyph: "󰔏"
          label: "温度"
          value: root.hasTemp ? root.temp + "°C" : "--°C"
          checked: root.showTemp
          onToggled: root.toggleItem("showTemp")
        }
      }
    }
  }

  // 一行类目：图标 + 名称，右侧当前值 + 开关。关闭时整行内容降透明度。
  component StatRow: Item {
    id: row
    property string glyph: ""
    property string label: ""
    property string value: ""
    property bool checked: true
    signal toggled()

    implicitWidth: Style.space(280)
    implicitHeight: Style.space(32)

    Item {
      id: rowContent
      anchors.left: parent.left
      anchors.right: sw.left
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      implicitHeight: Math.max(glyphText.implicitHeight, labelText.implicitHeight)
      opacity: row.checked ? 1.0 : 0.45

      Behavior on opacity { NumberAnimation { duration: 120 } }

      Text {
        id: glyphText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: row.glyph
        color: root.fg
        font.family: root.labelFont
        font.pixelSize: Style.font.iconLarge
      }

      Text {
        id: labelText
        anchors.left: glyphText.right
        anchors.leftMargin: Style.space(12)
        anchors.verticalCenter: parent.verticalCenter
        text: row.label
        color: root.fg
        font.family: root.labelFont
        font.pixelSize: Style.font.subtitle
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: row.value
        color: Qt.darker(root.fg, 1.6)
        font.family: root.labelFont
        font.pixelSize: Style.font.bodySmall
      }
    }

    ToggleSwitch {
      id: sw
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      checked: row.checked
      foreground: root.fg
      onToggled: row.toggled()

      PanelToolTip {
        visible: sw.containsMouse && sw.checked && root.enabledCount <= 1
        text: "至少保留一项开启"
        fontFamily: root.labelFont
      }
    }
  }
}
