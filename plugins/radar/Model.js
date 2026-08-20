function parseConfig(raw) {
  var defaults = { station: "KFCX", name: "KFCX" }
  try {
    var data = JSON.parse(String(raw || ""))
    if (!data || typeof data !== "object") return defaults
    var station = String(data.station || defaults.station).toUpperCase().replace(/[^A-Z0-9-]/g, "")
    return {
      station: station || defaults.station,
      name: String(data.name || station || defaults.name)
    }
  } catch (e) {
    return defaults
  }
}

function parseStations(raw) {
  try {
    var features = JSON.parse(String(raw || "{}")).features || []
    var result = []
    for (var i = 0; i < features.length; i++) {
      var p = features[i].properties || {}
      var id = String(p.stationIdentifier || p.id || "").toUpperCase()
      if (!id || id.length !== 4) continue
      result.push({
        id: id,
        name: String(p.name || id),
        state: String(p.state || ""),
        latitude: Number(p.latitude),
        longitude: Number(p.longitude)
      })
    }
    return result
  } catch (e) {
    return []
  }
}

function filterStations(stations, query) {
  var q = String(query || "").toLowerCase().replace(/^\s+|\s+$/g, "")
  var result = []
  for (var i = 0; i < stations.length && result.length < 6; i++) {
    var s = stations[i]
    var hay = (s.id + " " + s.name + " " + s.state).toLowerCase()
    if (!q || hay.indexOf(q) !== -1) result.push(s)
  }
  return result
}

function loopUrl(stationId, revision) {
  return "https://radar.weather.gov/ridge/standard/"
    + String(stationId || "KFCX")
    + "_loop.gif?r="
    + String(revision || 0)
}

function viewerSettings(stationId, longitude, latitude) {
  var center = (isFinite(longitude) && isFinite(latitude))
    ? [longitude, latitude]
    : [-80.274, 37.024]
  return {
    agenda: {
      id: "local",
      center: center,
      zoom: 8,
      filter: "WSR-88D",
      layer: "bref_raw",
      station: stationId,
      animating: true,
      transparent: true,
      alertsOverlay: true,
      stationIconsOverlay: false
    },
    base: "standard",
    county: false,
    cwa: false,
    menu: true,
    shortFusedOnly: false,
    state: false
  }
}

function stationById(stations, stationId) {
  for (var i = 0; i < stations.length; i++) {
    if (stations[i].id === stationId) return stations[i]
  }
  return null
}
