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

    // How much of Spotlight's pane is its own ground rather than what is
    // behind it. Near opaque by default, so it reads over anything; with a
    // blur layer rule on `shell-spotlight` in the compositor, lower it — 0.75
    // or so — to let the frosted desktop through.
    readonly property real glassOpacity: value("glassOpacity", 0.94)

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

    // How long a notification is kept in the panel after it has left the
    // screen, in seconds, and how many of them are kept at most. Everything
    // older than the one or beyond the other is dropped on its own; anything
    // younger stays until it is dismissed.
    readonly property int notificationRetention: value("notificationRetention", 24 * 60 * 60)
    readonly property int notificationLimit: value("notificationLimit", 50)

    // Applications that keep a volume of their own and put their stream back
    // to it whenever the track changes, without ever reading the stream's
    // volume back. Spotify is one: turn its stream down in the panel and the
    // next song comes up at whatever its own slider says. The panel sets
    // these through mpris as well, so the application's own volume is the
    // one the bar was dragged to. Matched against the stream's
    // `application.name`, case aside.
    readonly property var mprisVolumeApps: value("mprisVolumeApps", ["spotify"])

    // The terminal the launcher runs a console application in — `htop`,
    // `nvim` — as `<terminal> -e <command>`. Empty runs the application as
    // it is, which for most of those means nothing you can see happens.
    readonly property string terminal: value("terminal", "")

    // ── authentication ────────────────────────────────────────────────────

    // Whether the shell is the session's polkit agent, the thing that asks
    // for a password when something wants to do what it needs one for. Only
    // one agent can answer for a session; turn this off to leave it to
    // another one — hyprpolkitagent, polkit-gnome — that the session runs.
    readonly property bool polkitAgent: value("polkitAgent", true)

    // ── motion ────────────────────────────────────────────────────────────

    // Wayland has no `prefers-reduced-motion` the shell can ask for, so this
    // is the switch: set, everything that moves arrives instead.
    readonly property bool reducedMotion: value("reducedMotion", false)

    // The curves the shell moves on, named and written the way hyprland's
    // are, so one set of them can be handed to both: a bezier by its two
    // control points, and a spring by its stiffness, dampening and mass. The
    // defaults are the ones in the hyprland config the notch was drawn
    // against. Given here, a curve is added to these or replaces the one of
    // the same name.
    readonly property var curves: Object.assign({
        easeOutQuint: {
            type: "bezier",
            points: [[0.23, 1], [0.32, 1]]
        },
        easeOutExpo: {
            type: "bezier",
            points: [[0.16, 1], [0.3, 1]]
        },
        almostLinear: {
            type: "bezier",
            points: [[0.5, 0.5], [0.75, 1]]
        },
        linear: {
            type: "bezier",
            points: [[0, 0], [1, 1]]
        },
        quick: {
            type: "bezier",
            points: [[0.15, 0], [0.1, 1]]
        },
        // slightly underdamped: settles with a soft overshoot
        soft: {
            type: "spring",
            stiffness: 200,
            dampening: 24,
            mass: 1
        },
        // close to critically damped
        snappy: {
            type: "spring",
            stiffness: 320,
            dampening: 34,
            mass: 1
        }
    }, value("curves", {}))

    // ...and which of them each kind of movement is made on, by hyprland's
    // name for the nearest thing it animates, with a speed in tenths of a
    // second the way hyprland counts it. A spring has no speed: it takes as
    // long as it takes to settle. Given here, an animation replaces the one
    // of the same name.
    readonly property var animations: Object.assign({
        // the notch growing and shrinking
        windows: {
            curve: "soft"
        },
        // anything going from one place to another: the notch and the
        // volume coming out of the top edge, a knob, a dot, a fill, a control
        // giving under a press
        windowsMove: {
            curve: "snappy"
        },
        // a ground or an ink changing, the way a border takes the focus
        border: {
            curve: "easeOutQuint",
            speed: 5
        },
        // something fading in, and out
        fadeIn: {
            curve: "almostLinear",
            speed: 1.7
        },
        fadeOut: {
            curve: "almostLinear",
            speed: 1.5
        },
        // a toast, a row or a section of a page arriving, and the rest
        // making room for it
        layersIn: {
            curve: "easeOutQuint",
            speed: 4
        },
        layers: {
            curve: "easeOutQuint",
            speed: 3.8
        },
        // one page making way for another
        workspaces: {
            curve: "easeOutExpo",
            speed: 4
        }
    }, value("animations", {}))
}
