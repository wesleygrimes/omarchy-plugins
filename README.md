# Omarchy plugins

Personal Omarchy shell plugins, dogfooded on this machine before they are ever listed in the [plugin directory](https://omarchyplugins.com).

Each plugin is a complete Omarchy plugin folder: its own `manifest.json`, QML, README, and license. The monorepo is for building and using them locally. Publishing later means giving that one folder its own git repo with `manifest.json` at the root — `omarchy plugin add` and the directory both require that.

## Local install

Omarchy discovers third-party plugins from `~/.config/omarchy/plugins/<id>/`. A symlink is enough, and `omarchy plugin remove` unlinks it.

```sh
git clone https://github.com/wesleygrimes/omarchy-plugins.git ~/Work/omarchy-plugins
~/Work/omarchy-plugins/bin/install --enable
```

That links every plugin in `plugins/`, rescans the shell, and enables new bar widgets. Saved edits reload automatically. To install one plugin:

```sh
bin/install radar --enable
```

Other machines, or a second Omarchy install, clone this repo and run `bin/install`. There is no marketplace URL in the loop.

```sh
bin/check                  # omarchy plugin validate on every plugin
bin/uninstall [name]       # unlink without deleting this checkout
bin/new short-name "Name"  # scaffold plugins/short-name as wes.short-name
```

## Ground rules

Keep these small. Add process only when a second plugin actually needs it.

1. **One folder, one plugin.** `plugins/<short-name>/` is a valid plugin on its own. No shared QML library until three plugins would copy the same code.
2. **IDs are `wes.<short-name>`.** Never `omarchy.*`. That namespace is reserved.
3. **Look like Omarchy.** Bar popovers use `BarWidget` + `Panel` + `KeyboardPanel`, `qs.Ui` / `qs.Commons`, and `Style.space(380)` unless the content truly cannot fit (clock and weather are the exceptions in first-party).
4. **No extra daemons.** Prefer `curl`, files under `~/.local/state/omarchy/settings/`, and stock `omarchy` commands. Plugins run unsandboxed inside `omarchy-shell`.
5. **Validate before commit.** `bin/check` must pass. `qmllint` the QML when you touch it.
6. **Dogfood first.** Enable it here, use it for real, then publish. A public git repo is not a listing on omarchyplugins.com.
7. **Publish as a dedicated repo.** Copy or `git subtree split -P plugins/<name>` into a repo whose root is the plugin. Submit only after it has been boring for a while.

## Plugins

| Folder | ID | What it is |
| --- | --- | --- |
| [`plugins/radar`](plugins/radar) | `wes.radar` | NWS RIDGE loop popover, default station KFCX |

## Later plugin ideas

Radar is the right first one if it stays a popover: current NWS loop, pick a station, open the full viewer when you need RadarScope-level detail. Lightning and storm reports can wait.

Things that fit the same shape, if a daily itch shows up:

- **Next-hour rain** — compact precipitation timing next to weather, not another map.
- **Calendar agenda** — next few events; the clock already owns the month grid.
- **Home controls** — lights / thermostat if you already have a local API.
- **VPN / tunnel** — only if Tailscale's built-in widget is not the one you use.
- **Inbox glance** — GitHub review queue or mail count; keep it a number plus a short list.
- **Scratch note** — one box, one file, Escape to close.

Do not start from a full-bar replacement, a WebEngine app, or anything that needs its own long-running service.

## Publishing later

When a plugin is actually ready:

```sh
gh repo create wesleygrimes/omarchy-wes-radar --public --source /tmp/radar --push
# or: git subtree split -P plugins/radar -b radar-publish
```

Then `omarchy plugin add https://github.com/wesleygrimes/omarchy-wes-radar.git` and, if you still want it listed, the form at [omarchyplugins.com/publish](https://omarchyplugins.com/publish.html).
