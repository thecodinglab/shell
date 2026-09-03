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
        // read before the first frame; the notch geometry depends on it
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
    //
    // The notch is deliberately monochrome plus one accent, so it only needs
    // the ground, the ink, the accent and a colour for things that are wrong.

    readonly property string base00: value("base00", "#1e1e2e") // background
    readonly property string base05: value("base05", "#cdd6f4") // foreground
    readonly property string base08: value("base08", "#f38ba8") // red, urgent
    readonly property string base0D: value("base0D", "#89b4fa") // blue, accent

    // ── typography ────────────────────────────────────────────────────────

    // One family carries the whole surface. Names, figures and labels are all
    // set in the sans; the mono is here for the nerd font glyphs alone, which
    // is the only thing on the notch that needs a particular file installed.
    readonly property string sansFamily: value("sansFamily", "Inter")
    readonly property string monoFamily: value("monoFamily", "JetBrainsMono Nerd Font Mono")

    // ...and the optical size the large type is cut at. Inter ships a display
    // cut drawn for exactly the job the clock does — read at a glance, from
    // across a room — so a session set in Inter gets it. Anything else has
    // one drawing and is set in it at both sizes, which is what empty means.
    readonly property string displayFamily: value("displayFamily", root.sansFamily === "Inter" ? "Inter Display" : "")

    // The notch was drawn against a 10pt base. Everything in Theme is a
    // multiple of it, so raising this grows the whole surface, not just text.
    readonly property real fontSize: value("fontSize", 10)

    // ...and how large the notch is over and above that. The font size is the
    // session's — stylix hands it over, and it is the size the rest of the
    // desktop is set in — while this one belongs to the notch alone, for when
    // the surface wants to be bigger than that text alone would make it. 1 is
    // the drawing at the size it was drawn.
    readonly property real scale: value("scale", 1.25)

    // Locale used for the clock and the date. Empty means "whatever the
    // session is set to".
    readonly property string locale: value("locale", "")
    readonly property bool twelveHour: value("twelveHour", false)

    // ── modules ───────────────────────────────────────────────────────────

    readonly property string diskPath: value("diskPath", "/")
    readonly property string networkInterface: value("networkInterface", "enp13s0")

    // Interfaces the notch does not count as ways out of the machine: bridges,
    // container veths and the like, matched by the start of their name.
    readonly property var networkIgnore: value("networkIgnore", ["veth", "docker", "br-", "virbr", "vnet"])

    // A monitor's dots are the workspaces hyprland's rules bind to it. On a
    // monitor with no such rules they are the first this many instead, so the
    // collapsed notch keeps its width instead of twitching every time one
    // opens or closes.
    readonly property int workspaceCount: value("workspaceCount", 5)

    // How long a notification sits under the notch before it fades out. The
    // sender can ask for less; it can never ask for more.
    readonly property int notificationTimeout: value("notificationTimeout", 6000)
}
