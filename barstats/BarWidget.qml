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
  property var cpuHistory: []

  readonly property color fg: root.bar ? root.bar.barForeground : Commons.Color.popups.text
  readonly property string compactText: root.cpu + "% " + root.memPercent + "% " + (root.hasTemp ? root.temp + "°C" : "--°C")

  function update(raw) {
    try {
      var data = JSON.parse(String(raw).trim())
      if (data.cpu !== undefined) {
        root.cpu = data.cpu
        root.cpuHistory = root.cpuHistory.slice(-29).concat(data.cpu)
      }
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
        spacing: Style.space(14)

        Text {
          text: "System"
          color: root.fg
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        // CPU
        Column {
          spacing: Style.space(6)

          Row {
            spacing: Style.space(8)
            Text {
              text: "CPU"
              color: root.fg
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
            }
            Text {
              text: root.cpu + "%"
              color: root.fg
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }

          ProgressBar {
            width: Style.space(180)
            value: root.cpu / 100
            foreground: root.fg
          }

          CpuGraph {
            width: Style.space(180)
            height: Style.space(32)
            history: root.cpuHistory
            foreground: root.fg
          }
        }

        // Memory
        Column {
          spacing: Style.space(6)

          Row {
            spacing: Style.space(8)
            Text {
              text: "Memory"
              color: root.fg
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
            }
            Text {
              text: root.memUsedGb.toFixed(1) + " / " + root.memTotalGb.toFixed(1) + " GB  (" + root.memPercent + "%)"
              color: root.fg
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }

          ProgressBar {
            width: Style.space(180)
            value: root.memPercent / 100
            foreground: root.fg
          }
        }

        // Temperature
        Row {
          spacing: Style.space(8)
          Text {
            text: "Temperature"
            color: root.fg
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
          }
          Text {
            text: root.hasTemp ? root.temp + "°C" : "--°C"
            color: root.fg
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }
        }
      }
    }
  }

  component ProgressBar: Item {
    property real value: 0
    property color foreground: "white"
    implicitWidth: width
    implicitHeight: Style.space(6)

    Rectangle {
      anchors.fill: parent
      radius: height / 2
      color: Util.alpha(foreground, 0.15)
    }

    Rectangle {
      width: Math.max(height, parent.width * Math.max(0, Math.min(1, value)))
      height: parent.height
      radius: height / 2
      color: foreground
    }
  }

  component CpuGraph: Item {
    property var history: []
    property color foreground: "white"

    Row {
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      spacing: 2

      Repeater {
        model: history
        Rectangle {
          required property var modelData
          width: Math.max(2, Math.floor(parent.width / 30) - 2)
          height: parent.height * Math.max(0.05, Math.min(1, (modelData || 0) / 100))
          anchors.bottom: parent.bottom
          color: foreground
          radius: 1
        }
      }
    }
  }
}
