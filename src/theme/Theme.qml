pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Colours and metrics for the notch.
//
// The design was drawn at a 10pt base against a dark palette: a 30px tall
// pill 6px below the top edge, growing into a 560px wide slab. Every number
// below is that drawing, multiplied by `scale` so a larger font size — or a
// larger `Config.scale` — grows the whole surface instead of just overflowing
// it.
//
// Colours are derived rather than named. The slab is the flat background
// colour, and anything painted on top of it is either an alpha wash of the
// foreground (surfaces, borders, tracks) or the foreground mixed toward the
// background (text). Both resolve against the slab, not the desktop: the
// shell is opaque, so nothing behind it shows through.
Singleton {
    id: root

    // ── palette ───────────────────────────────────────────────────────────

    readonly property color accent: Config.base0D
    readonly property color urgent: Config.base08
    // ink for the one thing that sits on top of the accent
    readonly property color onAccent: Config.base00

    // The slab, and the pill it collapses to. Both are the flat background
    // colour: the shell is opaque, so nothing behind it reads through.
    readonly property color slab: Config.base00
    readonly property color slabCollapsed: Config.base00
    // ...and the ground an urgent notification sits on, which is the same
    // slab pushed toward the red it is warning with rather than a wash of it
    readonly property color slabUrgent: root.mix(Config.base00, Config.base08, 0.12)
    readonly property color slabBorder: root.alpha(Config.base05, 0.08)
    // ...and what it casts on the desktop behind it. Black rather than a
    // wash of the palette: it falls on whatever window the shell has opened
    // over, which the palette says nothing about.
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.45)

    // cards and rows sitting on the slab, plus their hovered state
    readonly property color surface: root.alpha(Config.base05, 0.04)
    readonly property color surfaceHover: root.alpha(Config.base05, 0.08)
    // the tint a selected or connected thing gets
    readonly property color accentSurface: root.alpha(Config.base0D, 0.10)
    readonly property color accentBorder: root.alpha(Config.base0D, 0.18)
    readonly property color urgentSurface: root.alpha(Config.base08, 0.10)
    readonly property color urgentBorder: root.alpha(Config.base08, 0.18)

    // slider and progress tracks
    readonly property color track: root.alpha(Config.base05, 0.11)
    // a bar graph's older samples, so the recent ones stand out against them
    readonly property color graphPast: root.alpha(Config.base0D, 0.45)

    // a workspace that exists but is not focused, and one that does not exist
    readonly property color dotOccupied: root.alpha(Config.base05, 0.42)
    readonly property color dotEmpty: root.alpha(Config.base05, 0.16)

    // five tiers of ink, brightest to faintest
    readonly property color text: Config.base05
    readonly property color textBody: root.mix(Config.base05, Config.base00, 0.14)
    readonly property color textMuted: root.mix(Config.base05, Config.base00, 0.38)
    readonly property color textDim: root.mix(Config.base05, Config.base00, 0.55)
    readonly property color textFaint: root.mix(Config.base05, Config.base00, 0.70)

    // ── typography ────────────────────────────────────────────────────────

    readonly property string sansFamily: Config.sansFamily
    readonly property string monoFamily: Config.monoFamily

    // the drawing's px sizes, by the job they do
    readonly property int fontTiny: root.px(9)     // stat captions
    readonly property int fontSmall: root.px(10)   // metadata, section labels
    readonly property int fontMeta: root.px(11)    // percentages, the date
    readonly property int fontBody: root.px(12)    // row names, body copy
    readonly property int fontTitle: root.px(13)   // panel titles, stat values
    readonly property int fontClock: root.px(14)   // the clock, collapsed and expanded

    // ── metrics ───────────────────────────────────────────────────────────

    // everything scales off the configured font size, times the notch's own
    // multiplier on top of it; 10pt at 1x is what the notch was drawn at
    readonly property real scale: Config.fontSize / 10 * Config.scale

    readonly property int collapsedHeight: root.px(30)
    readonly property int collapsedPadding: root.px(14)
    // between the workspace dots and the clock
    readonly property int collapsedSpacing: root.px(16)

    // The strip along the top edge that the hidden notch listens on. It runs
    // the full width of the screen, and is the only part of it the shell
    // occupies while folded away, so it is kept thin: deep enough that a
    // pointer thrown at the top edge lands in it, shallow enough that it is
    // not in anything's way.
    readonly property int revealHeight: root.px(4)

    readonly property int expandedWidth: root.px(560)
    readonly property int expandedPadding: root.px(12)
    // between the stacked sections of a panel
    readonly property int expandedSpacing: root.px(12)

    // The window has to be tall enough for the tallest thing it can show, and
    // it is masked down to the slab, so being generous costs nothing.
    readonly property int windowHeight: root.px(640)
    // A list grows the slab until the notch would be taller than half the
    // screen — see `Notch.bodyMaxHeight` — and scrolls from there. This is the
    // floor under that: if a panel's own chrome leaves less than this, the
    // list gets it anyway, because a list you cannot see two rows of is not a
    // list.
    readonly property int listMinHeight: root.px(120)

    readonly property int slabRadius: root.px(20)
    readonly property int cardRadius: root.px(14)
    readonly property int rowRadius: root.px(12)
    readonly property int tagRadius: root.px(6)

    // How far the shadow under a floating surface reaches, and how far down
    // it is pushed: enough to lift the surface off the window behind it,
    // short of it reading as a second surface of its own.
    readonly property int shadowBlur: root.px(28)
    readonly property int shadowOffset: root.px(6)

    readonly property int cardPadding: root.px(10)
    readonly property int rowPadding: root.px(10)
    readonly property int rowSpacing: root.px(10)
    // gap between the rows of a list
    readonly property int listSpacing: root.px(6)

    // a glyph column, so icons in a list line up regardless of their width
    readonly property int iconWidth: root.px(16)
    readonly property int sliderHeight: root.px(6)
    readonly property int sliderKnob: root.px(14)
    readonly property int meterHeight: root.px(3)
    readonly property int graphHeight: root.px(30)

    // A scrollbar: the band that is drawn, and the column it is drawn in,
    // which is wider than the band so there is something to grab at.
    readonly property int scrollThickness: root.px(3)
    readonly property int scrollGutter: root.px(10)

    // the ring that turns while a device is making up its mind
    readonly property int spinnerSize: root.px(12)
    readonly property int spinnerThickness: root.px(2)

    // A dial: the outside diameter of the ring, and the width of the band it
    // is drawn with. The larger one is for the resources panel, where a gauge
    // is the subject of its card rather than one of three in a tile.
    readonly property int gaugeSize: root.px(54)
    readonly property int gaugeLarge: root.px(66)
    readonly property int gaugeThickness: root.px(5)
    // ...and the room it is given around it, so a dial in a row of them is not
    // set flush against the next thing along
    readonly property int gaugePadding: root.px(3)
    readonly property int artSize: root.px(76)

    readonly property int dotSize: root.px(6)
    // the focused workspace stretches into a bar instead of growing
    readonly property int dotActiveWidth: root.px(16)
    readonly property int dotSpacing: root.px(6)

    readonly property int toastWidth: root.px(380)
    readonly property int toastSpacing: root.px(8)

    // ── motion ────────────────────────────────────────────────────────────

    // the slab unfolding, and the crossfade between what it held before and
    // what it holds now
    readonly property int expandDuration: 260
    readonly property int fadeDuration: 140
    readonly property int expandEasing: Easing.OutCubic
    // the hidden notch sliding back out of the top edge; quicker than the
    // unfold, because it happens under a pointer that is already moving
    readonly property int revealDuration: 180
    // one turn of a spinner; slow enough to read as waiting rather than as
    // something having gone wrong
    readonly property int spinDuration: 900

    // a pointer clipping the top edge on its way somewhere else should not
    // pull the notch out
    readonly property int hoverDelay: 120
    // ...and leaving it for a moment should not put it away again
    readonly property int collapseDelay: 240

    // ── helpers ───────────────────────────────────────────────────────────

    // a design-unit length in real pixels
    function px(units: real): int {
        return Math.round(units * root.scale);
    }

    function alpha(c: color, a: real): color {
        const q = Qt.color(c);
        return Qt.rgba(q.r, q.g, q.b, a);
    }

    // `t` of the way from `a` to `b`
    function mix(a: color, b: color, t: real): color {
        const x = Qt.color(a);
        const y = Qt.color(b);
        return Qt.rgba(x.r + (y.r - x.r) * t, x.g + (y.g - x.g) * t, x.b + (y.b - x.b) * t, x.a + (y.a - x.a) * t);
    }
}
