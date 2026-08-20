import QtQuick
import qs.Ui
import qs.Commons
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "wes.radar"

  readonly property bool opened: radarPanel.opened
  readonly property bool popoutSwitchClosing: radarPanel.popoutSwitchClosing

  function refresh() { radarPanel.refresh() }
  function togglePanel() { radarPanel.toggle() }
  function open() { radarPanel.openFromHotkey() }
  function close() { radarPanel.close() }
  function closeForPopoutSwitch() { radarPanel.closeForPopoutSwitch() }

  readonly property int iconFont: Style.barToken("icon-font", 13)
  readonly property int fontBody: Style.fontToken("body", Style.fontPx(1.0))

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  RadarPanel {
    id: radarPanel
    visible: false
    bar: root.bar
    settings: root.settings
    anchorItem: button
    hostWidget: root
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    labelVisible: false
    hasVisualContent: radarPanel.label !== ""
    implicitWidth: root.vertical
      ? barSize
      : content.implicitWidth + Style.spaceReal(8.75) * 2
    horizontalMargin: 8.75
    verticalPadding: 8.75
    tooltipText: ""
    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.MiddleButton) root.refresh()
      else if (b === Qt.LeftButton) root.togglePanel()
    }

    Row {
      id: content
      visible: !root.vertical
      anchors.centerIn: parent
      spacing: Style.space(6)

      Text {
        text: Model.iconGlyph()
        color: button.foreground
        font.family: button.fontFamily
        font.pixelSize: root.iconFont
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: radarPanel.label
        color: button.foreground
        font.family: button.fontFamily
        font.pixelSize: root.fontBody
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Text {
      visible: root.vertical
      anchors.centerIn: parent
      text: Model.iconGlyph()
      color: button.foreground
      font.family: button.fontFamily
      font.pixelSize: root.iconFont
    }
  }
}
