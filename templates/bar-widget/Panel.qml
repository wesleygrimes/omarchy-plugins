import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "@ID@"
  ipcTarget: "@ID@"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  property string label: "@SHORT@"

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { if (root.opened) close(); else open() }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        Text {
          text: "@NAME@"
          color: root.fg
          font.family: root.fontFamily
          font.bold: true
          font.pixelSize: Style.font.subtitle
        }

        Text {
          width: parent.width
          text: "Replace this popover with the real widget."
          color: Color.muted
          font.family: root.fontFamily
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
