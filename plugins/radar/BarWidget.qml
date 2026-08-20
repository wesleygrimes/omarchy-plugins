import QtQuick
import qs.Ui

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
    text: radarPanel.label
    horizontalMargin: 8.75
    verticalPadding: 8.75
    tooltipText: ""
    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.MiddleButton) root.refresh()
      else if (b === Qt.LeftButton) root.togglePanel()
    }
  }
}
