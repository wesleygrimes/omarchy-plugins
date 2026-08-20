import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "wes.radar"
  ipcTarget: "wes.radar"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  property bool openedFromHotkey: false

  property string label: stationId
  property string stationId: "KFCX"
  property string stationName: "KFCX"
  property string searchText: ""
  property var stations: []
  property var suggestions: []
  property string imageUrl: ""
  property string errorText: ""
  property int imageRevision: 0
  property bool loadingStations: false
  property bool editingStation: false
  property bool hasSavedStation: false

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property real radarHeight: Math.round(Style.space(380) * 550 / 600)

  function open() {
    openedFromHotkey = false
    setCenterHoverRevealSuppressed(false)
    showAndRefresh()
  }

  function openFromHotkey() {
    openedFromHotkey = true
    showAndRefresh()
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
  }

  function showAndRefresh() {
    root.controller.show()
    configFile.reload()
    root.refresh()
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    root.editingStation = false
    root.searchText = ""
    root.suggestions = []
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) close()
    else openFromHotkey()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  function refresh() {
    if (!stationId) return
    errorText = ""
    imageRevision++
    imageUrl = Model.loopUrl(stationId, imageRevision)
  }

  function loadStations() {
    if (loadingStations || stations.length) return
    loadingStations = true
    stationsProc.running = true
  }

  function startEditingStation() {
    editingStation = true
    searchText = ""
    loadStations()
    updateSuggestions()
    Qt.callLater(function() {
      search.forceActiveFocus()
      search.selectAll()
    })
  }

  function cancelEditingStation() {
    editingStation = false
    searchText = ""
    suggestions = []
  }

  function updateSuggestions() {
    suggestions = Model.filterStations(stations, searchText)
  }

  function chooseStation(s) {
    if (!s) return
    stationId = s.id
    stationName = s.name
    label = s.id
    cancelEditingStation()
    configFile.setText(JSON.stringify({ version: 1, station: stationId, name: stationName }, null, 2) + "\n")
    refresh()
  }

  function chooseSearchStation() {
    var typed = String(searchText || "").toUpperCase().replace(/^\s+|\s+$/g, "")
    if (/^[A-Z]{4}$/.test(typed)) {
      chooseStation({ id: typed, name: typed })
      return
    }
    var index = stationList.currentIndex >= 0 ? stationList.currentIndex : 0
    if (suggestions.length) chooseStation(suggestions[index])
  }

  function currentStation() {
    return Model.stationById(stations, stationId)
  }

  function viewerUrl() {
    var station = currentStation()
    var lon = station ? station.longitude : NaN
    var lat = station ? station.latitude : NaN
    return "https://radar.weather.gov/?settings=v1_" + encodeURIComponent(Qt.btoa(JSON.stringify(Model.viewerSettings(stationId, lon, lat))))
  }

  function openViewer() {
    Quickshell.execDetached(["omarchy-launch-browser", viewerUrl()])
  }

  FileView {
    id: configFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/wes-radar.json"
    watchChanges: true
    printErrors: false
    onLoaded: {
      var c = Model.parseConfig(text())
      root.hasSavedStation = true
      root.stationId = c.station
      root.stationName = c.name
      root.label = c.station
    }
    onLoadFailed: {
      root.hasSavedStation = false
      root.stationId = "KFCX"
      root.stationName = "KFCX"
      root.label = "KFCX"
    }
  }

  Process {
    id: ensureDirsProc
    command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/omarchy/settings"]
  }

  Process {
    id: stationsProc
    command: [
      "curl", "-fsS", "--max-time", "12",
      "-H", "User-Agent: wes.radar-omarchy/0.1 (+https://github.com/wesleygrimes/omarchy-plugins)",
      "https://api.weather.gov/radar/stations?limit=500"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.stations = Model.parseStations(text)
        root.loadingStations = false
        root.updateSuggestions()
        if (!root.stations.length) root.errorText = "Could not load NWS station list"
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 300000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.openFromHotkey() }
    function close(): void { root.close() }
    function show(): void { root.openFromHotkey() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.editingStation
      onCloseRequested: {
        if (root.editingStation) root.cancelEditingStation()
        else root.close()
      }
      onReturnRequested: { if (root.editingStation) root.chooseSearchStation() }
      onActivateRequested: { if (root.editingStation) root.chooseSearchStation() }
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (!root.editingStation) root.startEditingStation()
      }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroLabels.implicitHeight, search.implicitHeight)

          Column {
            id: heroLabels
            visible: !root.editingStation
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "RADAR"
              color: root.fg
              font.family: root.fontFamily
              font.bold: true
              font.pixelSize: Style.font.caption
            }

            Text {
              width: parent.width
              text: root.stationName + "  ·  " + root.stationId
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: heroLabels
            visible: heroLabels.visible
            cursorShape: Qt.PointingHandCursor
            onClicked: root.startEditingStation()
          }

          TextField {
            id: search
            visible: root.editingStation
            anchors.left: parent.left
            anchors.right: parent.right
            foreground: root.fg
            font.family: root.fontFamily
            placeholderText: "Station id or name"
            text: root.searchText
            onVisibleChanged: if (visible) root.loadStations()
            onTextChanged: {
              root.searchText = text
              root.updateSuggestions()
            }
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Down) {
                if (root.suggestions.length)
                  stationList.currentIndex = Math.min(stationList.currentIndex + 1, root.suggestions.length - 1)
                event.accepted = true
              } else if (event.key === Qt.Key_Up) {
                if (root.suggestions.length)
                  stationList.currentIndex = Math.max(stationList.currentIndex - 1, 0)
                event.accepted = true
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.chooseSearchStation()
                event.accepted = true
              } else if (event.key === Qt.Key_Escape) {
                root.cancelEditingStation()
                event.accepted = true
              }
            }
          }
        }

        ListView {
          id: stationList
          width: parent.width
          height: root.editingStation && root.suggestions.length ? Style.space(34) * Math.min(4, root.suggestions.length) : 0
          visible: height > 0
          clip: true
          model: root.suggestions
          currentIndex: root.suggestions.length ? 0 : -1
          delegate: Rectangle {
            width: stationList.width
            height: Style.space(34)
            color: (stationList.currentIndex === index || mouse.containsMouse) ? Color.accent : "transparent"

            Row {
              anchors.fill: parent
              anchors.margins: Style.space(6)
              spacing: Style.space(10)
              Text {
                text: modelData.id
                color: root.fg
                font.family: root.fontFamily
                font.bold: true
                width: Style.space(52)
              }
              Text {
                text: modelData.name + (modelData.state ? " (" + modelData.state + ")" : "")
                color: root.fg
                font.family: root.fontFamily
                elide: Text.ElideRight
                width: parent.width - Style.space(62)
              }
            }

            MouseArea {
              id: mouse
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.chooseStation(modelData)
            }
          }
        }

        Rectangle {
          width: parent.width
          height: root.radarHeight
          color: Color.background
          border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
          clip: true

          AnimatedImage {
            id: radarImage
            anchors.fill: parent
            anchors.margins: 1
            source: root.opened ? root.imageUrl : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            playing: root.opened && status === Image.Ready
            onStatusChanged: {
              if (status === Image.Error)
                root.errorText = "Could not load NWS radar loop"
              else if (status === Image.Ready)
                root.errorText = ""
            }
          }

          Text {
            anchors.centerIn: parent
            visible: radarImage.status === Image.Loading || radarImage.status === Image.Null
            text: "Loading loop…"
            color: Color.muted
            font.family: root.fontFamily
          }
        }

        Item {
          width: parent.width
          implicitHeight: Math.max(statusText.implicitHeight, actionRow.implicitHeight)

          Text {
            id: statusText
            anchors.left: parent.left
            anchors.right: actionRow.left
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            text: root.errorText || "NWS RIDGE loop · click station to change"
            color: root.errorText ? Color.urgent : Color.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }

          Row {
            id: actionRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Button {
              text: "Refresh"
              foreground: root.fg
              onClicked: root.refresh()
            }

            Button {
              text: "Open map"
              foreground: root.fg
              onClicked: root.openViewer()
            }
          }
        }
      }
    }
  }

  Component.onCompleted: ensureDirsProc.running = true
}
