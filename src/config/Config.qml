pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Every value the shell can be tuned with, in one place.
//
// Defaults live here so the config is runnable straight from a checkout
// (`quickshell -p src`). The nix build drops a `config.json` next to
// `shell.qml` which overrides any subset of them, so the home-manager module
// can feed in stylix colors, fonts and host specific settings.
Singleton {
    id: root

    FileView {
        id: file

        path: `${Quickshell.shellDir}/config.json`
        // read before the first frame; the bar geometry depends on it
        blockLoading: true
        // a missing config.json just means "use the defaults"
        printErrors: false
    }

    readonly property var overrides: {
        const text = file.text();
        if (!text)
            return ({});

        try {
            return JSON.parse(text) ?? {};
        } catch (e) {
            console.warn(`config.json is not valid json, ignoring it: ${e}`);
            return ({});
        }
    }

    function value(key: string, fallback: var): var {
        const v = root.overrides[key];
        return v === undefined ? fallback : v;
    }

    // ── base16 palette ────────────────────────────────────────────────────
    // defaults: catppuccin mocha, matching modules/home-manager/theme/theme.yaml

    readonly property string base00: value("base00", "#1e1e2e") // background
    readonly property string base05: value("base05", "#cdd6f4") // foreground
    readonly property string base08: value("base08", "#f38ba8") // red, urgent
    readonly property string base0D: value("base0D", "#89b4fa") // blue, active

    // ── typography ────────────────────────────────────────────────────────

    readonly property string fontFamily: value("fontFamily", "JetBrainsMono Nerd Font Mono")
    readonly property real fontSize: value("fontSize", 10)

    // Locale used for the clock. Empty means "whatever the session is set to",
    // which is what waybar's strftime did.
    readonly property string locale: value("locale", "")

    // ── modules ───────────────────────────────────────────────────────────

    readonly property string diskPath: value("diskPath", "/")
    readonly property string networkInterface: value("networkInterface", "enp13s0")
}
