pragma Singleton

import QtQuick
import Quickshell
import qs.config

// The design system: one neutral scale, one accent, one family, a 4-unit
// grid, and the handful of durations everything moves in.
//
// The notch was drawn at a 10pt base. Every length below is a design unit
// put through `px()`, which multiplies it by the session's font size and by
// `Config.scale`, so a larger font grows the whole surface rather than
// overflowing it. Layout lengths are multiples of four units; strokes and
// hairlines are not, because they are not layout.
//
// Nothing outside this file names a colour, a size or a duration. A widget
// that needs one reads it from here, and a panel that needs a gap reads one
// of the spacing tokens.
Singleton {
    id: root

    // ── mode ──────────────────────────────────────────────────────────────

    // Light and dark are told apart by the palette's ground rather than by a
    // setting: a base16 scheme with a light base00 is a light scheme.
    readonly property bool light: root.luminance(Config.base00) > 0.5

    // ── neutral scale ─────────────────────────────────────────────────────

    // Twelve steps from the ground (base00) to the ink (base05). The two
    // modes are spaced differently: on a dark ground the eye needs bigger
    // steps low down, where the grounds are, and on a light one the ink has
    // to be pushed further toward full strength before it reads as text.
    //
    //   0      the ground behind everything: the ink on a filled control
    //   1..3   the sheet and the washes a row shows under the pointer
    //   4..6   the ground under a disc, an empty track, and their hover
    //   7      a workspace that exists but is not here
    //   8      disabled ink, the last tier that still passes as large text
    //   9..11  the three tiers of text: dim, muted, and full
    readonly property var steps: root.light ? [0, 0.04, 0.07, 0.10, 0.13, 0.17, 0.24, 0.36, 0.62, 0.84, 0.92, 1] : [0, 0.045, 0.08, 0.12, 0.16, 0.22, 0.30, 0.40, 0.50, 0.62, 0.74, 1]
    readonly property var neutral: root.steps.map(t => root.mix(Config.base00, Config.base05, t))

    // ── grounds ───────────────────────────────────────────────────────────

    // The sheet, and the pill it collapses to. Dark, it is lifted one step
    // off the palette's ground so it reads as a material over the windows it
    // opens on top of; light, it is the ground itself and the shadow does
    // that job.
    readonly property color slab: root.neutral[root.light ? 0 : 1]
    // the hairline along its edge, for when it opens over a window of the
    // same colour
    readonly property color slabBorder: root.neutral[root.light ? 4 : 3]
    // the sheet pushed toward the red an urgent notification warns with
    readonly property color slabUrgent: root.mix(root.slab, root.urgent, 0.10)

    // a row on the sheet has no ground until the pointer finds it
    readonly property color rowHover: root.neutral[2]
    readonly property color rowPress: root.neutral[3]

    // the ground under a disc, a button, an empty track — something raised
    // off the sheet — and the two steps it takes under the pointer
    readonly property color surface: root.neutral[4]
    readonly property color surfaceHover: root.neutral[5]
    readonly property color surfacePress: root.neutral[6]

    // the hairline between two rows, or two sections
    readonly property color rule: root.neutral[3]
    // the empty part of a track, and a graph's older samples
    readonly property color track: root.neutral[4]

    // What the sheet casts on the desktop. Black rather than a wash of the
    // palette, because it falls on whatever window is behind it; lighter in
    // light mode, where a heavy shadow reads as dirt.
    readonly property color shadow: Qt.rgba(0, 0, 0, root.light ? 0.16 : 0.36)

    // ── ink ───────────────────────────────────────────────────────────────

    // Four tiers. Hierarchy is carried by these and by weight before it is
    // carried by size.
    readonly property color text: root.neutral[11]
    readonly property color textMuted: root.neutral[10]
    readonly property color textDim: root.neutral[9]
    // disabled, and nothing that has to be read
    readonly property color textFaint: root.neutral[8]

    // A slider's fill is the ink itself, so a bar at half reads as a solid
    // thing rather than a coloured one; what is drawn over it is the ground.
    readonly property color fill: root.neutral[11]
    readonly property color onFill: root.neutral[0]

    // ── accent, and the one semantic colour ───────────────────────────────

    // Spent on state alone: on, here, focused. Never on decoration.
    readonly property color accent: Config.base0D
    readonly property color onAccent: Config.base00
    readonly property color accentSurface: root.mix(root.slab, root.accent, 0.16)

    // The palette's red, pulled a little toward the ink so it warns without
    // shouting, and the wash and hairline an urgent surface is drawn with.
    readonly property color urgent: root.mix(Config.base08, Config.base05, 0.12)
    readonly property color urgentSurface: root.mix(root.slab, root.urgent, 0.14)
    readonly property color urgentBorder: root.mix(root.slab, root.urgent, 0.32)

    // the workspaces: one that exists but is not focused, and one that does
    // not exist yet
    readonly property color dotOccupied: root.neutral[7]
    readonly property color dotEmpty: root.neutral[4]

    // ── typography ────────────────────────────────────────────────────────

    readonly property string sansFamily: Config.sansFamily
    readonly property string monoFamily: Config.monoFamily
    // the large sizes, which fall back to the one drawing when the session's
    // face has no separate display cut
    readonly property string displayFamily: Config.displayFamily || Config.sansFamily

    // Four sizes. Small for metadata and figures, body for everything read,
    // title for the name of a page and the clock on the pill, display for the
    // clock at the head of the page.
    readonly property int fontSmall: root.px(11)
    readonly property int fontBody: root.px(12)
    readonly property int fontTitle: root.px(15)
    readonly property int fontDisplay: root.px(28)

    // Tabular figures, for anything that changes on a timer: a proportional
    // 1 is narrower than a proportional 4, so a clock ticking over would
    // otherwise reflow the row it is in.
    readonly property var tabular: ({
            tnum: 1
        })

    // ── spacing ───────────────────────────────────────────────────────────

    // everything scales off the configured font size, times the notch's own
    // multiplier on top of it; 10pt at 1x is what the notch was drawn at
    readonly property real scale: Config.fontSize / 10 * Config.scale

    // The grid: four units, and the steps of it a layout may use.
    readonly property int space1: root.px(4)
    readonly property int space2: root.px(8)
    readonly property int space3: root.px(12)
    readonly property int space4: root.px(16)
    readonly property int space5: root.px(20)
    readonly property int space6: root.px(24)
    readonly property int space8: root.px(32)

    // The page margin: everything on the sheet hangs off it, and the rows
    // that bleed past it do so by their own padding.
    readonly property int pagePadding: root.space4
    // between the sections of a page, and between the things in one
    readonly property int sectionSpacing: root.space5
    readonly property int stackSpacing: root.space2

    // a row's own padding, and the gap between the things laid across it
    readonly property int rowPadding: root.space2
    readonly property int rowSpacing: root.space3
    // between a name and the line under it
    readonly property int lineGap: root.px(2)

    // ── radius ────────────────────────────────────────────────────────────

    // Three. Small for anything on the sheet — a row's hover ground, a piece
    // of artwork, a tooltip; medium for a field; large for the floating
    // surfaces themselves, the slab and a toast. Anything round is a pill.
    readonly property int radiusSmall: root.px(6)
    readonly property int radiusMedium: root.px(12)
    readonly property int radiusLarge: root.px(24)

    // ── the notch ─────────────────────────────────────────────────────────

    readonly property int collapsedHeight: root.space8
    readonly property int collapsedPadding: root.space3
    // between the workspace dots and the clock: wider than the padding around
    // them, so the pill reads as two things rather than six at one interval
    readonly property int collapsedSpacing: root.space5

    // The strip along the top edge the hidden notch listens on: deep enough
    // that a pointer thrown at the top edge lands in it, shallow enough that
    // it is not in anything's way.
    readonly property int revealHeight: root.space1

    // Narrow, for a notch: a control centre is a column read top to bottom,
    // not a dashboard read across.
    readonly property int expandedWidth: root.px(440)
    // The window has to be tall enough for the tallest thing it can show, and
    // it is masked down to the sheet, so being generous costs nothing.
    readonly property int windowHeight: root.px(640)
    // A list grows the sheet until the notch would be taller than half the
    // screen — see `Notch.bodyMaxHeight` — and scrolls from there. This is the
    // floor under that: a list you cannot see two rows of is not a list.
    readonly property int listMinHeight: root.px(120)

    // one soft shadow, under the floating surfaces only
    readonly property int shadowBlur: root.space8
    readonly property int shadowOffset: root.space2

    // ── controls ──────────────────────────────────────────────────────────

    // the disc an icon sits in: on a row, on a tile, and under a session
    // mark at the foot of the page
    readonly property int discSizeSmall: root.px(28)
    readonly property int discSize: root.space8
    readonly property int discSizeLarge: root.px(36)

    // a glyph column, so icons in a list line up regardless of their width
    readonly property int iconWidth: root.space5
    // the round hit area of a glyph you can press
    readonly property int actionSize: root.px(28)
    // a button with a word on it
    readonly property int buttonHeight: root.px(28)
    readonly property int buttonPadding: root.space3
    // a count on the shoulder of a button
    readonly property int badgeHeight: root.px(14)
    // A figure column. Every right-aligned number on the surface is set in
    // one of these, so the column holds still and the numbers line up down
    // the page rather than each row ending wherever its own value did.
    readonly property int figureWidth: root.px(36)

    // a switch, and the knob inside it
    readonly property int switchWidth: root.px(32)
    readonly property int switchHeight: root.px(18)
    readonly property int switchInset: root.px(2)

    // A slider is a bar you drag by its fill, with the glyph for what it sets
    // sitting inside it at the left. Tall, because the bar is the whole
    // control — there is no knob to hit.
    readonly property int sliderHeight: root.space6
    // the least a bar may be squeezed to and still be dragged
    readonly property int sliderMinWidth: root.px(120)
    // ...except a scrubber, which is read far more often than it is dragged
    // and grows under the pointer when it is
    readonly property int scrubHeight: root.px(4)
    readonly property int scrubHeightActive: root.px(6)
    // ...and a level meter, which is only ever read
    readonly property int meterHeight: root.px(4)
    readonly property int graphHeight: root.space8
    readonly property int graphGap: root.px(2)

    // A scrollbar: the band that is drawn, and the column it is drawn in,
    // which is wider than the band so there is something to grab at.
    readonly property int scrollThickness: root.px(3)
    readonly property int scrollGutter: root.space3

    // the ring that turns while a device is making up its mind
    readonly property int spinnerSize: root.space4
    readonly property int spinnerThickness: root.px(2)

    // A dial: the outside diameter of the ring, the width of the band it is
    // drawn with, and the room it is given around it. Large, one to a row in
    // the system page; and tiny, the ring inside the system tile's disc.
    readonly property int gaugeSize: root.px(64)
    readonly property int gaugeThickness: root.px(4)
    readonly property int gaugePadding: root.space1
    readonly property int ringThickness: root.px(2)
    readonly property int artSize: root.px(64)

    readonly property int dotSize: root.px(6)
    // the focused workspace stretches into a bar instead of growing
    readonly property int dotActiveWidth: root.space5
    readonly property int dotSpacing: root.space2

    // the ring around whatever has keyboard focus
    readonly property int focusWidth: root.px(2)

    // ── floating surfaces ─────────────────────────────────────────────────

    readonly property int toastWidth: root.px(360)
    readonly property int toastPadding: root.space4
    readonly property int toastSpacing: root.space2
    // the sender's icon at the head of a toast
    readonly property int toastIconSize: root.px(36)

    // The reading that drops out of the top edge when the volume is set from
    // the keyboard: narrower than a notification, because it carries one
    // bar and a figure rather than a line of prose.
    readonly property int osdWidth: root.px(240)
    readonly property int osdPadding: root.space2
    readonly property int osdTrackHeight: root.px(4)

    readonly property int tooltipPadding: root.space2
    readonly property int tooltipDelay: 500
    // one breath of a block that is still loading
    readonly property int pulseDuration: 700

    // ── motion ────────────────────────────────────────────────────────────

    // Everything that moves is scaled by this; with reduced motion on it is
    // nought, and everything arrives instead.
    readonly property real motion: Config.reducedMotion ? 0 : 1

    // the sheet unfolding, and the crossfade between what it held before and
    // what it holds now
    readonly property int expandDuration: 240 * root.motion
    readonly property int fadeDuration: 150 * root.motion
    readonly property int expandEasing: Easing.OutCubic
    // The curve the sheet itself grows on: nearly all of the distance is
    // covered in the first third and it settles from there, so the notch
    // arrives as fast as it can without stopping dead.
    readonly property var expandCurve: [0.32, 0.72, 0, 1, 1, 1]
    // the hidden notch sliding back out of the top edge; quicker than the
    // unfold, because it happens under a pointer that is already moving
    readonly property int revealDuration: 180 * root.motion
    // what the page waits before fading in, so the sheet is already most of
    // the way open underneath it
    readonly property int staggerDelay: 90 * root.motion
    // one turn of a spinner: not scaled, a spinner that does not spin is a
    // spinner that has stopped
    readonly property int spinDuration: 900
    // how long the volume reading stays out after the last key press
    readonly property int osdHold: 1500
    // how long a mark that has to be pressed twice — restart, shut down —
    // waits for the second press before letting the first one go
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

    // `t` of the way from `a` to `b`
    function mix(a: color, b: color, t: real): color {
        const x = Qt.color(a);
        const y = Qt.color(b);
        return Qt.rgba(x.r + (y.r - x.r) * t, x.g + (y.g - x.g) * t, x.b + (y.b - x.b) * t, x.a + (y.a - x.a) * t);
    }

    // relative luminance, the way the contrast rules measure it
    function luminance(c: color): real {
        const q = Qt.color(c);
        const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * lin(q.r) + 0.7152 * lin(q.g) + 0.0722 * lin(q.b);
    }
}
