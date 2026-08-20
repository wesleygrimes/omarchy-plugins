# Radar

NWS radar loop as an Omarchy bar popover, sized like the network and audio panels.

The bar shows the station id (KFCX by default). Click it for the current RIDGE reflectivity loop. Click the station name to search. Middle-click the bar icon to refresh. "Open map" launches the interactive radar.weather.gov viewer in the browser when the loop is not enough.

This is not RadarScope. Lightning and storm reports are out of scope until the loop is something you actually open during weather.

## Install

From the monorepo checkout:

```sh
bin/install radar --enable
```

That places it in the center section, after the built-in weather widget.

## Use

- Left click: open or close the popover
- Middle click: refresh the loop
- Click the station name: search NEXRAD (WSR-88D) sites by id or name
- Scroll the loop: zoom toward the cursor
- Drag when zoomed: pan
- Double-click the loop, or `0`: reset zoom
- `+` / `-`: zoom in or out
- Escape: close
- Open map: full NWS viewer in the default browser

The chosen station is stored in `~/.local/state/omarchy/settings/wes-radar.json`.

## Data

- Loop: `https://radar.weather.gov/ridge/standard/<STATION>_loop.gif` (WSR-88D only)
- Stations: `https://api.weather.gov/radar/stations`

Search and typing a station id only accept WSR-88D sites. Airport TDWR (TTPA) and profilers are omitted because RIDGE does not publish loops for them.

NWS asks that automated access send a User-Agent with contact info. The plugin does.

## Publish later

This folder is the plugin. When it has been dogfooded, split it into its own repo with `manifest.json` at the root and run `omarchy plugin add <url>`.
