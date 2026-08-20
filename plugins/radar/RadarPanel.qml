pragma ComponentBehavior: Bound
import QtQuick
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
  property real zoom: 1
  property real panX: 0
  property real panY: 0
  property real wheelAccumulator: 0
  property real dragPanX: 0
  property real dragPanY: 0
  property real dragStartX: 0
  property real dragStartY: 0
  readonly property real minZoom: 1
  readonly property real maxZoom: 5

  readonly property color fg: root.barForeground
  readonly property string fontFamily: Style.fontFamily
  readonly property int fontCaption: Style.fontToken("caption", Style.fontPx(0.833))
  readonly property int fontBody: Style.fontToken("body", Style.fontPx(1.0))
  readonly property int fontDisplay: Style.fontToken("display", Style.fontPx(2.0))
  readonly property real radarHeight: Math.round(Style.space(380) * 550 / 600)
  readonly property string stationTitle: Model.displayName(stationName, stationId)
  readonly property string stationCode: Model.displayCode(stationName, stationId)

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
    root.loadStations()
    root.refresh()
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    root.editingStation = false
    root.searchText = ""
    root.suggestions = []
    root.resetZoom()
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) close()
    else openFromHotkey()
  }

  function barProperty(name) {
    return root.bar ? root.bar[name] : undefined
  }

  function switchPanel(direction) {
    var fn = barProperty("switchPanelFrom")
    if (typeof fn !== "function") return false
    return fn.call(root.bar, root.barIdentity, direction)
  }

  function setCenterHoverRevealSuppressed(value) {
    if (barProperty("centerHoverRevealSuppressed") === undefined) return
    root.bar["centerHoverRevealSuppressed"] = value
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

  function persistStation() {
    configFile.setText(JSON.stringify({ version: 1, station: stationId, name: stationName }, null, 2) + "\n")
  }

  function applyResolvedStation() {
    var s = Model.stationById(stations, stationId)
    if (s && Model.isWsr88d(s)) {
      var nextName = s.name || stationId
      if (nextName === stationName) return
      stationName = nextName
      persistStation()
      return
    }
    if (!stations.length) return
    var fallback = s
      ? Model.nearestWsr(stations, s.latitude, s.longitude)
      : Model.stationById(stations, "KFCX")
    if (!fallback || fallback.id === stationId) return
    stationId = fallback.id
    stationName = fallback.name || fallback.id
    label = fallback.id
    persistStation()
    refresh()
  }

  function chooseStation(s) {
    if (!s || !Model.isWsr88d(s)) return
    stationId = s.id
    stationName = s.name || s.id
    label = s.id
    cancelEditingStation()
    resetZoom()
    persistStation()
    applyResolvedStation()
    refresh()
  }

  function chooseSearchStation() {
    chooseStation(Model.resolveSearch(stations, suggestions, stationList.currentIndex, searchText))
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

  function resetZoom() {
    zoom = 1
    panX = 0
    panY = 0
    wheelAccumulator = 0
  }

  function applyPan(nextX, nextY) {
    var clamped = Model.clampPan(zoom, nextX, nextY, radarViewport.width, radarViewport.height)
    panX = clamped.panX
    panY = clamped.panY
  }

  function zoomAt(factor, viewX, viewY) {
    var next = Model.nextZoom(zoom, factor, minZoom, maxZoom)
    if (next === zoom) {
      applyPan(panX, panY)
      return
    }
    var originX = Number(viewX) - radarViewport.width / 2
    var originY = Number(viewY) - radarViewport.height / 2
    var panned = Model.panAfterZoom(zoom, next, panX, panY, originX, originY)
    zoom = next
    applyPan(panned.panX, panned.panY)
  }

  function zoomBy(factor) {
    zoomAt(factor, radarViewport.width / 2, radarViewport.height / 2)
  }

  function zoomIn() { zoomBy(1.2) }
  function zoomOut() { zoomBy(1 / 1.2) }

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
      root.applyResolvedStation()
    }
    onLoadFailed: {
      root.hasSavedStation = false
      root.stationId = "KFCX"
      root.stationName = "KFCX"
      root.label = "KFCX"
      root.applyResolvedStation()
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
      "https://api.weather.gov/radar/stations"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.stations = Model.parseStations(text)
        root.loadingStations = false
        root.updateSuggestions()
        root.applyResolvedStation()
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
        if (t === "+" || t === "=") { root.zoomIn(); return }
        if (t === "-" || t === "_") { root.zoomOut(); return }
        if (t === "0") { root.resetZoom(); return }
        if (!root.editingStation) root.startEditingStation()
      }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        Item {
          width: parent.width
          implicitHeight: root.editingStation ? search.implicitHeight : hero.implicitHeight

          PanelHero {
            id: hero
            visible: !root.editingStation
            width: parent.width
            title: root.stationTitle
            detail: root.stationCode
            meta: "Change station"
            foreground: root.fg
            fontFamily: root.fontFamily
            iconComponent: Component {
              Text {
                text: "󰐼"
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: root.fontDisplay
              }
            }
          }

          MouseArea {
            anchors.fill: hero
            visible: hero.visible
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
            id: stationRow
            required property var modelData
            required property int index
            readonly property bool active: ListView.view.currentIndex === index || mouse.containsMouse
            readonly property color rowFg: active
              ? Style.hoverStateColor(root.fg, Color.accent)
              : root.fg
            width: ListView.view.width
            height: Style.space(34)
            radius: Style.cornerRadius
            color: active ? Style.hoverFillFor(root.fg, Color.accent) : "transparent"

            Row {
              anchors.fill: parent
              anchors.margins: Style.space(6)
              spacing: Style.space(10)
              Text {
                text: stationRow.modelData.id
                color: stationRow.rowFg
                font.family: root.fontFamily
                font.bold: true
                width: Style.space(52)
              }
              Text {
                text: stationRow.modelData.name + (stationRow.modelData.state ? " (" + stationRow.modelData.state + ")" : "")
                color: stationRow.rowFg
                font.family: root.fontFamily
                elide: Text.ElideRight
                width: parent.width - Style.space(62)
              }
            }

            MouseArea {
              id: mouse
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.chooseStation(stationRow.modelData)
            }
          }
        }

        Rectangle {
          id: radarViewport
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
            transform: [
              Scale {
                xScale: root.zoom
                yScale: root.zoom
                origin.x: radarImage.width / 2
                origin.y: radarImage.height / 2
              },
              Translate {
                x: root.panX
                y: root.panY
              }
            ]
            onStatusChanged: {
              if (status === Image.Error)
                root.errorText = "Could not load NWS radar loop"
              else if (status === Image.Ready)
                root.errorText = ""
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: root.zoom > 1
              ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
              : Qt.ArrowCursor
            onWheel: function(wheel) {
              var result = Util.wheelSteps(root.wheelAccumulator, wheel.angleDelta.y)
              root.wheelAccumulator = result.remainder
              if (result.steps !== 0) {
                var factor = result.steps > 0 ? Math.pow(1.2, result.steps) : Math.pow(1 / 1.2, -result.steps)
                root.zoomAt(factor, wheel.x, wheel.y)
              }
              wheel.accepted = true
            }
            onPressed: function(mouse) {
              root.dragStartX = mouse.x
              root.dragStartY = mouse.y
              root.dragPanX = root.panX
              root.dragPanY = root.panY
            }
            onPositionChanged: function(mouse) {
              if (!(mouse.buttons & Qt.LeftButton) || root.zoom <= 1) return
              root.applyPan(root.dragPanX + (mouse.x - root.dragStartX), root.dragPanY + (mouse.y - root.dragStartY))
            }
            onDoubleClicked: root.resetZoom()
          }

          Text {
            anchors.centerIn: parent
            visible: radarImage.status === Image.Loading || radarImage.status === Image.Null
            text: "Loading loop…"
            color: Color.muted
            font.family: root.fontFamily
          }

          Column {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Style.space(6)
            spacing: Style.space(4)

            Button {
              text: "+"
              foreground: root.fg
              onClicked: root.zoomIn()
            }

            Button {
              text: "−"
              foreground: root.fg
              onClicked: root.zoomOut()
            }
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
            text: root.errorText || (root.zoom > 1
              ? Model.zoomLabel(root.zoom) + " · drag to pan · double-click to reset"
              : "NEXRAD loop · scroll to zoom")
            color: root.errorText ? Color.urgent : Color.muted
            font.family: root.fontFamily
            font.pixelSize: root.fontCaption
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

  Component.onCompleted: {
    ensureDirsProc.running = true
    root.loadStations()
  }
}
