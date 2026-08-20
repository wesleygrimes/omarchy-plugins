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

function parseStationFeature(feature) {
  if (!feature || typeof feature !== "object") return null
  var p = feature.properties || {}
  var id = String(p.stationIdentifier || p.id || "").toUpperCase().replace(/[^A-Z0-9]/g, "")
  if (!id || id.length !== 4) return null
  var coords = (feature.geometry && feature.geometry.coordinates) || []
  var name = String(p.name || "").replace(/^\s+|\s+$/g, "")
  return {
    id: id,
    name: name || id,
    state: String(p.state || ""),
    stationType: String(p.stationType || ""),
    latitude: Number(coords.length > 1 ? coords[1] : p.latitude),
    longitude: Number(coords.length > 0 ? coords[0] : p.longitude)
  }
}

function parseStations(raw) {
  try {
    var data = JSON.parse(String(raw || "{}"))
    if (data && data.type === "Feature") {
      var one = parseStationFeature(data)
      return one ? [one] : []
    }
    var features = (data && data.features) || []
    var result = []
    for (var i = 0; i < features.length; i++) {
      var station = parseStationFeature(features[i])
      if (station) result.push(station)
    }
    return result
  } catch (e) {
    return []
  }
}

function displayName(name, id) {
  var code = String(id || "").toUpperCase()
  var label = String(name || "").replace(/^\s+|\s+$/g, "")
  if (!label || label.toUpperCase() === code) return code
  return label
}

function displayCode(name, id) {
  var code = String(id || "").toUpperCase()
  var label = String(name || "").replace(/^\s+|\s+$/g, "")
  if (!label || label.toUpperCase() === code) return ""
  return code
}

function isWsr88d(station) {
  return String(station && station.stationType || "").toUpperCase() === "WSR-88D"
}

function filterStations(stations, query) {
  var q = String(query || "").toLowerCase().replace(/^\s+|\s+$/g, "")
  var result = []
  for (var i = 0; i < stations.length && result.length < 6; i++) {
    var s = stations[i]
    if (!isWsr88d(s)) continue
    var hay = (s.id + " " + s.name + " " + s.state).toLowerCase()
    if (!q || hay.indexOf(q) !== -1) result.push(s)
  }
  return result
}

function nearestWsr(stations, latitude, longitude) {
  var best = null
  var bestDistance = Infinity
  for (var i = 0; i < stations.length; i++) {
    var s = stations[i]
    if (!isWsr88d(s) || !isFinite(s.latitude) || !isFinite(s.longitude)) continue
    if (!isFinite(latitude) || !isFinite(longitude)) {
      if (!best) best = s
      continue
    }
    var dLat = s.latitude - latitude
    var dLon = s.longitude - longitude
    var distance = dLat * dLat + dLon * dLon
    if (distance < bestDistance) {
      bestDistance = distance
      best = s
    }
  }
  return best
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
  var code = String(stationId || "").toUpperCase()
  for (var i = 0; i < stations.length; i++) {
    if (stations[i].id === code) return stations[i]
  }
  return null
}

function resolveSearch(stations, suggestions, selectedIndex, query) {
  var typed = String(query || "").replace(/^\s+|\s+$/g, "")
  var code = typed.toUpperCase()
  var exact = /^[A-Z]{4}$/.test(code) ? stationById(stations, code) : null
  if (exact && isWsr88d(exact)) return exact

  var list = suggestions || []
  if (list.length) {
    var index = Math.max(0, Math.min(parseInt(selectedIndex, 10) || 0, list.length - 1))
    var pick = list[index] || list[0]
    if (pick && isWsr88d(pick)) return pick
  }

  return null
}

function clampNumber(n, min, max) {
  var v = Number(n)
  if (!isFinite(v)) return min
  return Math.max(min, Math.min(max, v))
}

function nextZoom(zoom, factor, minZoom, maxZoom) {
  return clampNumber(Math.round(Number(zoom) * Number(factor) * 20) / 20, minZoom, maxZoom)
}

function panAfterZoom(zoom, next, panX, panY, originX, originY) {
  if (!(Number(zoom) > 0)) return { panX: 0, panY: 0 }
  var scale = Number(next) / Number(zoom)
  return {
    panX: originX - (originX - panX) * scale,
    panY: originY - (originY - panY) * scale
  }
}

function clampPan(zoom, panX, panY, viewW, viewH) {
  if (!(Number(zoom) > 1)) return { panX: 0, panY: 0 }
  var maxX = Math.max(0, (Number(viewW) * (Number(zoom) - 1)) / 2)
  var maxY = Math.max(0, (Number(viewH) * (Number(zoom) - 1)) / 2)
  return {
    panX: clampNumber(panX, -maxX, maxX),
    panY: clampNumber(panY, -maxY, maxY)
  }
}

function zoomLabel(zoom) {
  return Math.round(Number(zoom) * 100) + "%"
}
