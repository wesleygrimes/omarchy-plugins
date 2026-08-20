# Agent instructions

This repository contains native Omarchy/Quickshell plugins. A successful file
edit, manifest validation, install, or shell restart is not visual
verification.

## Required verification

After changing plugin behavior or QML UI, run:

```sh
bin/verify-ui <plugin-folder>
```

That command validates the plugins, links and enables the selected plugin,
restarts the shell for a fresh component load, summons it, captures the real
desktop, and saves the screenshot plus relevant journal output under
`.artifacts/plugin-ui/`.

The agent must then:

1. Open and visually inspect the saved PNG with its image-viewing capability.
2. Read `shell.log` and resolve relevant QML/plugin errors.
3. Exercise every state affected by the change (for example search, empty,
   loading, error, expanded, and zoom states) and capture additional evidence
   when one screenshot cannot cover them.
4. Report what was actually observed. Never describe the UI as verified when
   the graphical session, capture, or interaction was unavailable.

For non-visual changes, `bin/check` is the minimum verification. QML changes
still require `bin/verify-ui`.

## Native UI notes

- These are Qt Quick surfaces inside `omarchy-shell`, not web pages. Playwright
  cannot inspect their DOM, console, or layout.
- Runtime diagnostics come from the user journal and QML `console.*` output.
- User plugin files hot-reload. Force a reload with
  `omarchy-shell shell rescanPlugins`; use `omarchy restart shell` only when
  hot reload is unhealthy.
- Browser automation is useful only for web pages opened by a plugin, not for
  the plugin panel itself.
