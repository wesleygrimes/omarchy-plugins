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
- Click the station name: search by id, name, or state
- Escape: close
- Open map: full NWS viewer in the default browser

The chosen station is stored in `~/.local/state/omarchy/settings/wes-radar.json`.

## Data

- Loop: `https://radar.weather.gov/ridge/standard/<STATION>_loop.gif`
- Stations: `https://api.weather.gov/radar/stations`

NWS asks that automated access send a User-Agent with contact info. The plugin does.

## Publish later

This folder is the plugin. When it has been dogfooded, split it into its own repo with `manifest.json` at the root and run `omarchy plugin add <url>`.
