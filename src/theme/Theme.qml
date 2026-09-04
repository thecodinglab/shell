pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Colours, type and metrics for the notch.
//
// The design was drawn at a 10pt base against a dark palette: a 32px tall
// pill hanging from the top edge, growing into a 440px wide slab. Every
// number below is that drawing, multiplied by `scale` so a larger font size —
// or a larger `Config.scale` — grows the whole surface instead of just
// overflowing it.
//
// The surface is built the way a control centre is: one flat slab, and on it
// a few modules cut from a single wash of the foreground. Nothing is framed
// and nothing is ruled; a module is told from the slab by its ground, and
// from its neighbour by the gap between them. The fills — a slider, a
// scrubber, the play button — are the ink itself, so the accent is left to
// say only one thing: this is on, or this is where you are.
Singleton {
    id: root

    // ── palette ───────────────────────────────────────────────────────────

    readonly property color accent: Config.base0D
    readonly property color urgent: Config.base08
    // ink for the one thing that sits on top of the accent
    readonly property color onAccent: Config.base00

    // The slab, and the pill it collapses to: the flat background colour.
    // The shell is opaque, so nothing behind it reads through.
    readonly property color slab: Config.base00
    // ...and the ground an urgent notification sits on, which is the same
    // slab pushed toward the red it is warning with rather than a wash of it
    readonly property color slabUrgent: root.mix(Config.base00, Config.base08, 0.12)
    readonly property color slabBorder: root.alpha(Config.base05, 0.10)
    // What the slab casts on the desktop behind it. Black rather than a wash
    // of the palette: it falls on whatever window the shell has opened over,
    // which the palette says nothing about. Two of them — see Shadow — one
    // wide and ambient, one tight enough to read as contact.
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.36)
    readonly property color shadowContact: Qt.rgba(0, 0, 0, 0.26)

    // The washes, brightest last. They are the whole material system, so
    // they are spaced far enough apart to be told apart at a glance.
    //
    // `surface` is a module's ground. A module that takes a click answers
    // the pointer by stepping up to `surfaceHover`, and up again while it is
    // held. `surfaceRaised` is a ground inside a ground — the disc behind an
    // icon, an empty track — which has to clear the module it is sitting on.
    readonly property color surface: root.alpha(Config.base05, 0.06)
    readonly property color surfaceHover: root.alpha(Config.base05, 0.10)
    readonly property color surfacePress: root.alpha(Config.base05, 0.14)
    readonly property color surfaceRaised: root.alpha(Config.base05, 0.12)
    // a row on the slab, which has no ground until the pointer finds it
    readonly property color rowHover: root.alpha(Config.base05, 0.07)
    readonly property color rowPress: root.alpha(Config.base05, 0.11)

    // A slider's fill, and the ink drawn over it. The fill is the foreground
    // itself — a volume bar is the most-touched control on the surface, and
    // it reads best as a solid thing rather than as a coloured one — pulled
    // back just enough that a bar at full does not glare against the slab.
    readonly property color fill: root.mix(Config.base05, Config.base00, 0.08)
    readonly property color onFill: Config.base00
    // the empty part of a track, and the hairline scrubber under a track
    readonly property color track: root.alpha(Config.base05, 0.12)

    // The tint a selected or connected thing gets. Accent is reserved for
    // where you are — position, selection, focus — so it is worth enough
    // contrast to be seen at a glance.
    readonly property color accentSurface: root.alpha(Config.base0D, 0.14)
    readonly property color urgentSurface: root.alpha(Config.base08, 0.14)
    readonly property color urgentBorder: root.alpha(Config.base08, 0.28)

    // a bar graph's older samples, so the recent ones stand out against them.
    // Neutral: history is not a state anything is in, and colouring it spends
    // the accent on the part of the graph nobody is reading.
    readonly property color graphPast: root.alpha(Config.base05, 0.16)

    // a workspace that exists but is not focused, and one that does not exist
    readonly property color dotOccupied: root.alpha(Config.base05, 0.42)
    readonly property color dotEmpty: root.alpha(Config.base05, 0.18)

    // five tiers of ink, brightest to faintest
    readonly property color text: Config.base05
    readonly property color textBody: root.mix(Config.base05, Config.base00, 0.14)
    readonly property color textMuted: root.mix(Config.base05, Config.base00, 0.38)
    readonly property color textDim: root.mix(Config.base05, Config.base00, 0.55)
    readonly property color textFaint: root.mix(Config.base05, Config.base00, 0.70)

    // ── typography ────────────────────────────────────────────────────────

    readonly property string sansFamily: Config.sansFamily
    readonly property string monoFamily: Config.monoFamily
    // the large sizes, which fall back to the one drawing when the session's
    // face has no separate display cut
    readonly property string displayFamily: Config.displayFamily || Config.sansFamily

    // Five sizes, spaced far enough apart to be a ramp. Hierarchy is carried
    // by weight and by ink as much as by size: a 1px step between two
    // neighbouring sizes is not a step anyone can see, so there is no point
    // paying for it with another name here.
    readonly property int fontSmall: root.px(11)    // metadata, figures, the date
    readonly property int fontBody: root.px(12)     // row names, body copy
    readonly property int fontTitle: root.px(14)    // panel titles, track titles
    readonly property int fontClock: root.px(15)    // the clock on the pill
    readonly property int fontDisplay: root.px(24)  // the clock at the head of the panel

    // Tabular figures, for anything that changes on a timer. This is what the
    // shell used to reach for a monospace face to get: a proportional 1 is
    // narrower than a proportional 4, so a clock ticking over reflows the row
    // it is in. `tnum` fixes that inside the sans, which keeps the surface in
    // one family instead of borrowing a terminal's.
    readonly property var tabular: ({
            tnum: 1
        })

    // ── metrics ───────────────────────────────────────────────────────────

    // everything scales off the configured font size, times the notch's own
    // multiplier on top of it; 10pt at 1x is what the notch was drawn at
    readonly property real scale: Config.fontSize / 10 * Config.scale

    readonly property int collapsedHeight: root.px(32)
    readonly property int collapsedPadding: root.px(14)
    // Between the workspace dots and the clock, and wider than the padding
    // around them: the pill holds two things, and the gap between them has
    // to be the biggest one on it or it reads as five dots and a clock all
    // set at the same interval.
    readonly property int collapsedSpacing: root.px(18)

    // The strip along the top edge that the hidden notch listens on. It runs
    // the full width of the screen, and is the only part of it the shell
    // occupies while folded away, so it is kept thin: deep enough that a
    // pointer thrown at the top edge lands in it, shallow enough that it is
    // not in anything's way.
    readonly property int revealHeight: root.px(4)

    // Narrow, for a notch: a control centre is a column of modules read top
    // to bottom, not a dashboard read across, and a slab that hangs from the
    // top edge should hang rather than span.
    readonly property int expandedWidth: root.px(440)
    readonly property int expandedPadding: root.px(12)
    // between the stacked modules of a panel
    readonly property int expandedSpacing: root.px(10)

    // The window has to be tall enough for the tallest thing it can show, and
    // it is masked down to the slab, so being generous costs nothing.
    readonly property int windowHeight: root.px(640)
    // A list grows the slab until the notch would be taller than half the
    // screen — see `Notch.bodyMaxHeight` — and scrolls from there. This is the
    // floor under that: if a panel's own chrome leaves less than this, the
    // list gets it anyway, because a list you cannot see two rows of is not a
    // list.
    readonly property int listMinHeight: root.px(120)

    // Radii nest: a corner inside another corner is the outer one less the
    // gap between them, so the two curves stay concentric instead of the
    // inner one bulging out of the outer. The slab is inset by
    // `expandedPadding`, so a module sitting directly on it is that much
    // rounder than nothing; a row inside a module is that much rounder again
    // than the module.
    readonly property int slabRadius: root.px(28)
    readonly property int cardRadius: root.slabRadius - root.expandedPadding
    readonly property int rowRadius: root.px(10)
    // Artwork is not in a corner of the card it sits in — it is a square in
    // the middle of one edge — so it is not concentric with anything and gets
    // a radius by eye instead.
    readonly property int artRadius: root.px(10)

    // How far the shadow under a floating surface reaches, and how far down
    // it is pushed. Two of them: a wide one that lifts the surface off the
    // desktop, and a tight one under its bottom edge that reads as the
    // surface touching what is behind it rather than floating over it.
    readonly property int shadowBlur: root.px(40)
    readonly property int shadowOffset: root.px(10)
    readonly property int shadowContactBlur: root.px(10)
    readonly property int shadowContactOffset: root.px(2)

    readonly property int cardPadding: root.px(12)
    readonly property int rowPadding: root.px(8)
    readonly property int rowSpacing: root.px(10)
    // gap between the rows of a list
    readonly property int listSpacing: root.px(2)

    // the disc an icon sits in on a tile or a row: big enough to be a mark
    // rather than a glyph, small enough for two of them a row apart
    readonly property int discSize: root.px(30)
    readonly property int discSizeSmall: root.px(26)

    // a glyph column, so icons in a list line up regardless of their width
    readonly property int iconWidth: root.px(18)
    // the round hit area of a glyph you can press
    readonly property int actionWidth: root.px(26)
    // A figure column. Every right-aligned number on the surface is set in
    // one of these, so the column holds still and the numbers in it line up
    // down the panel rather than each row ending wherever its own value did.
    readonly property int figureWidth: root.px(36)

    // A slider is a bar you drag by its fill, with the glyph for what it sets
    // sitting inside it at the left. Tall, because the bar is the whole
    // control — there is no knob to hit — and because the glyph has to fit
    // inside it with room to spare.
    readonly property int sliderHeight: root.px(26)
    // ...except a scrubber, which is read far more often than it is dragged
    // and grows under the pointer when it is
    readonly property int scrubHeight: root.px(4)
    readonly property int scrubHeightActive: root.px(6)
    readonly property int graphHeight: root.px(30)

    // A scrollbar: the band that is drawn, and the column it is drawn in,
    // which is wider than the band so there is something to grab at.
    readonly property int scrollThickness: root.px(3)
    readonly property int scrollGutter: root.px(10)

    // the ring that turns while a device is making up its mind
    readonly property int spinnerSize: root.px(12)
    readonly property int spinnerThickness: root.px(2)

    // A dial: the outside diameter of the ring, and the width of the band it
    // is drawn with. Two sizes — three abreast in the home strip, and one to a
    // card in the system panel, where it is the subject rather than one of a
    // set. The band is thin for its diameter at both, because the figure it
    // is standing in for has to sit inside it.
    readonly property int gaugeSize: root.px(52)
    readonly property int gaugeLarge: root.px(60)
    readonly property int gaugeThickness: root.px(4)
    // ...and the room it is given around it, so a dial in a row of them is not
    // set flush against the next thing along
    readonly property int gaugePadding: root.px(3)
    readonly property int artSize: root.px(56)

    readonly property int dotSize: root.px(6)
    // the focused workspace stretches into a bar instead of growing
    readonly property int dotActiveWidth: root.px(18)
    readonly property int dotSpacing: root.px(6)

    readonly property int toastWidth: root.px(360)
    readonly property int toastSpacing: root.px(8)
    readonly property int toastRadius: root.px(18)

    // The reading that drops out of the top edge when the volume is set from
    // the keyboard: narrower than a notification, because it carries one
    // bar and a figure rather than a line of prose, and a pill rather than a
    // card, because it is the notch's own shape at the notch's own size.
    readonly property int osdWidth: root.px(240)
    readonly property int osdPadding: root.px(10)
    // its bar is read, never dragged, so it is drawn at the scrubber's
    // hovered weight rather than the slider's
    readonly property int osdTrackHeight: root.px(6)

    // ── motion ────────────────────────────────────────────────────────────

    // the slab unfolding, and the crossfade between what it held before and
    // what it holds now
    readonly property int expandDuration: 300
    readonly property int fadeDuration: 150
    readonly property int expandEasing: Easing.OutCubic
    // The curve the slab itself grows on: nearly all of the distance is
    // covered in the first third and it settles from there, so the notch
    // arrives as fast as it can without stopping dead. Small things — a
    // hovered ground, a dot stretching — keep the plain cubic; the difference
    // is only legible over a distance.
    readonly property var expandCurve: [0.32, 0.72, 0, 1, 1, 1]
    // the hidden notch sliding back out of the top edge; quicker than the
    // unfold, because it happens under a pointer that is already moving
    readonly property int revealDuration: 190
    // What the panel waits before fading in, so the slab is already most of
    // the way open underneath it. Going the other way there is no wait: the
    // contents leave first and the slab closes over the gap.
    readonly property int staggerDelay: 90
    // one turn of a spinner; slow enough to read as waiting rather than as
    // something having gone wrong
    readonly property int spinDuration: 900
    // How long the volume reading stays out after the last key press: long
    // enough to be read, short enough that it is gone before it is in the
    // way of anything. Every press starts it over.
    readonly property int osdHold: 1500
    // How long a mark that has to be pressed twice — restart, shut down —
    // waits for the second press before letting the first one go. Long
    // enough to read what it is asking, short enough that a press left
    // behind by mistake is not still armed when the notch is next opened.
    readonly property int confirmHold: 4000

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
