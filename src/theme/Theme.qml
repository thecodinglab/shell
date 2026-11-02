pragma Singleton

import QtQuick
import Quickshell
import qs.config

// The design system: two materials — the bezel the notch is made of and the
// glass that floats out from under it — each one neutral scale and one
// accent, then one family, a 4-unit grid, and the handful of durations
// everything moves in.
//
// The colours are the materials' — see Scheme. A widget reads them from the
// one it stands on, `schemeOf(item)`, and a page that colours a thing of its
// own names the material outright: `Theme.bezel.text`, `Theme.pane.glass`.
//
// The notch was drawn at a 10pt base. Every length below is a design unit
// put through `px()`, which multiplies it by the session's font size and by
// `Config.scale`, so a larger font grows the whole surface rather than
// overflowing it. Layout lengths are multiples of four units; strokes and
// hairlines are not, because they are not layout.
//
// Nothing outside this file names a colour, a size or a duration, but for
// Scheme, which works the roles out of what this hands it. A widget that
// needs one reads it from here, and a panel that needs a gap reads one of the
// spacing tokens.
Singleton {
    id: root

    // ── mode ──────────────────────────────────────────────────────────────

    // Light and dark are told apart by the palette's ground rather than by a
    // setting: a base16 scheme with a light base00 is a light scheme.
    readonly property bool light: Paint.luminance(Config.base00) > 0.5
    // the palette's lighter and darker ends, whichever of base00 and base05
    // they happen to be
    readonly property color litEnd: root.light ? Config.base00 : Config.base05
    readonly property color dimEnd: root.light ? Config.base05 : Config.base00

    // Increased contrast pushes the hairlines and the quiet inks a step
    // harder, and with reduced transparency it makes the glass solid, the
    // way a mac does with either setting.
    readonly property bool contrastUp: Config.increaseContrast
    readonly property bool opaqueGlass: Config.reducedTransparency || Config.increaseContrast
    // How little of the glass may be its own ground. Every ink is measured
    // against the glass at this strength laid over pure white, or pure black,
    // with no blur behind it; a `glassOpacity` below it would let the desktop
    // decide whether a caption can be read.
    readonly property real glassFloor: 0.92
    readonly property real glassAlpha: root.opaqueGlass ? 1 : Math.max(root.glassFloor, Config.glassOpacity)

    // ── the two materials ─────────────────────────────────────────────────

    // The bezel: the pill, the tally, the ears, the open sheet and every
    // panel on it. It is the black of the screen's own frame, the way the
    // notch on a macbook is the bezel around it rather than a grey laid over
    // the windows, so it is dark whatever the palette is: the darker end of
    // it pushed most of the way to black, keeping its tint so the shell still
    // belongs to the scheme it is set in, with the lighter end as its ink.
    //
    // The steps are spaced for a dark ground, where the eye needs bigger
    // steps low down, where the grounds are. The seventh, a workspace that
    // exists, sits far enough up to clear 3:1 on a lit row, as a shape that
    // has to be told apart must.
    readonly property Scheme bezel: Scheme {
        ground: Paint.mix(root.dimEnd, "#000000", 0.55)
        ink: root.litEnd
        steps: [0, 0.045, 0.08, 0.12, 0.16, 0.22, 0.30, 0.45, 0.50, 0.62, 0.74, 1]
        accentBase: Config.base0D
        urgentBase: Config.base08
        contrastUp: root.contrastUp
    }

    // The pane: glass, for what floats over the windows rather than hanging
    // from the edge — a toast, the volume reading, Spotlight, the password
    // prompt. It follows the palette. Dark, its ground is the palette's
    // pushed a little toward black, lighter than the bezel it drops out from
    // under; light, the palette's own ground, with an ink pushed toward black
    // until there is room in it for four tiers of text. On a light ground the
    // ink has to be pushed further toward full strength before it reads as
    // text, so the upper steps are spaced wider.
    readonly property Scheme pane: Scheme {
        ground: root.light ? Config.base00 : Paint.mix(Config.base00, "#000000", 0.30)
        ink: root.light ? Paint.mix(Config.base05, "#000000", 0.35) : Config.base05
        steps: root.light ? [0, 0.04, 0.07, 0.10, 0.13, 0.17, 0.24, 0.36, 0.62, 0.80, 0.90, 1] : [0, 0.045, 0.08, 0.12, 0.16, 0.22, 0.30, 0.45, 0.55, 0.73, 0.84, 1]
        translucent: true
        alpha: root.glassAlpha
        accentBase: Config.base0D
        urgentBase: Config.base08
        contrastUp: root.contrastUp
    }

    // What the root of a glass surface is named, so everything drawn on it
    // can find out that it is on glass.
    readonly property string paneTag: "shell-pane"

    // Which material `item` stands on: the pane if anything it sits in is
    // tagged as glass, and the bezel otherwise. A widget that draws colour
    // asks this for the default of its `scheme`, rather than being told by
    // every page it is put on, and asks again if it is moved.
    function schemeOf(item: Item): Scheme {
        for (let p = item; p; p = p.parent)
            if (p.objectName === root.paneTag)
                return root.pane;
        return root.bezel;
    }

    // What a floating surface casts on the desktop. Black rather than a wash
    // of the palette, because it falls on whatever window is behind it;
    // lighter in light mode, where a heavy shadow reads as dirt.
    readonly property color shadow: Qt.rgba(0, 0, 0, root.light ? 0.16 : 0.36)

    // ── typography ────────────────────────────────────────────────────────

    readonly property string sansFamily: Config.sansFamily
    readonly property string monoFamily: Config.monoFamily
    // the large sizes, which fall back to the one drawing when the session's
    // face has no separate display cut
    readonly property string displayFamily: Config.displayFamily || Config.sansFamily

    // Four sizes, and Spotlight's field, on the steps a mac sets its own
    // text in: small for metadata and figures (its subheadline, 11), body
    // for everything read and every control with a word on it (its body,
    // 13), title for the name of a page and the clock on the pill (title
    // three, 15), display for the clock at the head of the page. Small sits
    // far enough under body that size carries some of the hierarchy, not
    // the ink alone.
    readonly property int fontSmall: root.px(11)
    readonly property int fontBody: root.px(13)
    readonly property int fontTitle: root.px(15)
    readonly property int fontDisplay: root.px(28)
    // ...and one more, for what is typed into Spotlight: the field is the
    // whole of it, and is set as large as a title would be on a page
    readonly property int fontSearch: root.px(22)

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
    readonly property int pagePadding: root.space5
    // between the sections of a page, and between the things in one
    readonly property int sectionSpacing: root.space5
    readonly property int stackSpacing: root.space2

    // a row's own padding, and the gap between the things laid across it
    readonly property int rowPadding: root.space2
    readonly property int rowSpacing: root.space3
    // between a name and the line under it
    readonly property int lineGap: root.px(2)

    // ── radius ────────────────────────────────────────────────────────────

    // Three. Small for a piece of artwork, a row's hover ground, a tooltip;
    // medium for what sits one page margin inside the sheet; large for
    // Spotlight's results. The corners of the surfaces themselves are worked
    // out from these, as the radius of what is inside plus the distance to
    // it, so a corner within a corner runs parallel to it all the way round
    // rather than pinching. Anything you press or type into is a capsule:
    // its radius is half its height.
    readonly property int radiusSmall: root.px(8)
    readonly property int radiusMedium: root.px(14)
    readonly property int radiusLarge: root.px(26)

    // ── the notch ─────────────────────────────────────────────────────────

    readonly property int collapsedHeight: root.space8
    readonly property int collapsedPadding: root.space4

    // The corners. Folded, the notch is the hardware one: a slot with its
    // bottom corners only softened. It rounds out as it unfolds, until the
    // sheet is the island it grew into, its corners concentric with the
    // medium ones a page margin inside it.
    readonly property int notchRadius: root.px(12)
    readonly property int notchRadiusOpen: root.pagePadding + root.radiusMedium
    // Where its sides meet the top edge they flare out into it rather than
    // standing on it at a right angle: a quarter of a circle cut out of the
    // corner either side, so the notch reads as part of the edge it hangs
    // from rather than as something stuck under it.
    readonly property int earRadius: root.px(10)
    // The line round the open sheet, down its sides and along its bottom
    // and never its top, that tells the bezel from a dark window it opens
    // over. A stroke rather than layout, so it is not on the grid.
    readonly property int keyLineWidth: root.px(1)

    // the bars that move on the pill while something is playing
    readonly property int waveBarWidth: root.px(3)
    readonly property int waveBarGap: root.px(2)
    readonly property int waveHeight: root.px(14)
    // how long one bar takes to rise and fall, the shortest of them; the
    // others are a little slower each, so the four never fall into step
    readonly property int waveDuration: 420
    readonly property int waveStagger: 70
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
    // How far down the screen the toasts may stack. The view has to be tall
    // enough to keep one on through its exit — see `Notch.toasts` — and the
    // window is masked down to what is in it, so being generous costs nothing.
    readonly property int windowHeight: root.px(640)
    // A list grows the sheet until the notch would be taller than half the
    // screen — see `Notch.bodyMaxHeight` — and scrolls from there. This is the
    // floor under that: a list you cannot see two rows of is not a list.
    readonly property int listMinHeight: root.px(120)

    // ── spotlight ─────────────────────────────────────────────────────────

    // A pane of its own rather than a page of the notch, floating over the
    // middle of the screen a little above its centre, where the eye already
    // is: wider than the notch, because what it carries is one long line of
    // type and a list read across.
    readonly property int spotlightWidth: root.px(640)
    // how far down the screen its top edge sits, as a share of the height
    readonly property real spotlightTop: 0.22
    // between the pane's edge and the rows inside it
    readonly property int spotlightPadding: root.space2
    // a row's corners, concentric with the sheet's at that inset
    readonly property int spotlightRowRadius: root.radiusLarge - root.spotlightPadding
    // between the field and the sheet of results hanging under it
    readonly property int spotlightGap: root.space2
    // the icon at the head of a result, and the larger one of the top hit
    readonly property int spotlightIconSize: root.space6
    readonly property int spotlightHitIconSize: root.px(40)
    // Enough rows to pick from, not a page of them: it is opened and put
    // away a hundred times a day.
    readonly property int spotlightListHeight: root.px(400)
    // What the blank field offers: the things that get used, up to this many.
    readonly property int spotlightRecents: 6
    // the size it opens from, and fades up out of
    readonly property real spotlightScale: 0.96

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
    readonly property int switchWidth: root.px(36)
    readonly property int switchHeight: root.space5
    readonly property int switchInset: root.px(2)

    // A slider is a bar you drag by its fill, with the glyph for what it sets
    // sitting inside it at the left. Tall, because the bar is the whole
    // control — there is no knob to hit.
    readonly property int sliderHeight: root.space6
    // the least a bar may be squeezed to and still be dragged
    readonly property int sliderMinWidth: root.px(120)
    // ...and the least height it is aimed at, however thin it is drawn: the
    // smallest target a pointer is given anywhere on the surface
    readonly property int sliderTarget: root.space5
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
    // how much of a disc its glyph fills
    readonly property real discGlyph: 0.55

    // A workspace: a dot, spaced so each one is a target of its own. The
    // focused one stretches into a bar instead of growing, and one asking
    // for attention into a shorter one, so it is told by its shape as well
    // as by the red.
    readonly property int dotSize: root.space2
    readonly property int dotActiveWidth: root.space6
    readonly property int dotUrgentWidth: root.px(14)
    readonly property int dotSpacing: root.space3

    // the ring around whatever has keyboard focus
    readonly property int focusWidth: root.px(2)

    // ── floating surfaces ─────────────────────────────────────────────────

    readonly property int toastWidth: root.px(360)
    readonly property int toastPadding: root.space4
    readonly property int toastSpacing: root.space2
    // concentric with the corner of the sender's icon, the padding in
    readonly property int toastRadius: root.toastPadding + root.radiusSmall
    // the sender's icon at the head of a toast
    readonly property int toastIconSize: root.px(36)

    // The reading that drops out of the top edge when the volume is set from
    // the keyboard: narrower than a notification, because it carries one
    // bar and a figure rather than a line of prose.
    readonly property int osdWidth: root.px(240)
    readonly property int osdPadding: root.space2
    readonly property int osdTrackHeight: root.px(6)

    readonly property int tooltipPadding: root.space2
    readonly property int tooltipDelay: 500
    // one breath of a block that is still loading
    readonly property int pulseDuration: 700

    // ── authentication ────────────────────────────────────────────────────

    // The polkit pane, drawn after the password prompt on a mac: Spotlight's
    // material at the width of a question rather than of a list, everything
    // on it centred down one column, and a little further down the screen
    // than Spotlight sits, because it is read before it is typed into.
    readonly property int polkitWidth: root.px(280)
    // how far down the screen its top edge sits, as a share of the height
    readonly property real polkitTop: 0.28
    // the requesting application's icon, or the padlock, at its head...
    readonly property int polkitIconSize: root.px(64)
    // ...and the padlock on the shoulder of an application's own, cut out
    // of the sheet by a rim so it stands clear of the icon under it
    readonly property int polkitBadgeSize: root.space6
    readonly property int polkitBadgeRim: root.px(2)
    // a field: who is asked, and the answer
    readonly property int polkitFieldHeight: root.space8
    // concentric with the capsules on it, a page margin in
    readonly property int polkitRadius: root.pagePadding + root.polkitFieldHeight / 2
    // the size it opens from, and fades up out of
    readonly property real polkitScale: 0.96
    // How hard a wrong answer knocks the pane sideways, in pixels a second:
    // it swings out and springs back, the way a login window shakes its head.
    readonly property int polkitShake: root.px(720)

    // ── privacy ───────────────────────────────────────────────────────────

    // the dot at the trailing end of the pill, lit in `Scheme.privacy`
    readonly property int privacyDot: root.space2
    // The tally the notch leaves on the top edge while it is put away and
    // something is in use: a slot just big enough to hold the dot, hanging
    // from the edge where the notch would, with ears of its own.
    readonly property int tallyWidth: root.space6
    readonly property int tallyHeight: root.space4
    readonly property int tallyEar: root.space1

    // ── motion ────────────────────────────────────────────────────────────
    //
    // Made the way hyprland makes its own — see `Config.curves` and
    // `Config.animations` — so the notch moves like the windows around it.
    // Everything that moves says which animation it is, by hyprland's name
    // for it, and reads its curve and its length from here: a spring, for
    // anything that can be sent somewhere new while it is still on its way
    // (see Spring), and a bezier for the rest.

    // Everything that moves is scaled by this; with reduced motion on it is
    // nought, and everything arrives instead.
    readonly property real motion: Config.reducedMotion ? 0 : 1

    // the curve an animation is made on, or null for one nobody has defined
    function curveOf(leaf: string): var {
        const animation = Config.animations[leaf];
        return animation ? Config.curves[animation.curve] ?? null : null;
    }

    // the spring an animation is made on, or null if it is not one
    function spring(leaf: string): var {
        const curve = root.curveOf(leaf);
        return curve?.type === "spring" ? curve : null;
    }

    // How long an animation runs, in milliseconds: a bezier's speed in tenths
    // of a second, as hyprland counts it, and a spring's time to come to
    // rest — for something that has to wait for one, or a transition that
    // can only be drawn on a bezier.
    function duration(leaf: string): int {
        const spring = root.spring(leaf);
        if (!spring)
            return Math.round((Config.animations[leaf]?.speed ?? 0) * 100 * root.motion);

        // The swing dies away as e^(-rate·t), at the slower of its two rates
        // when it is overdamped, and it is at rest once it is within a
        // thousandth of the way it had to go — where hyprland stops it.
        const mass = Math.max(spring.mass ?? 1, 0.0001);
        const omega = Math.sqrt(Math.max(spring.stiffness, 0.0001) / mass);
        const gamma = Math.max(spring.dampening, 0) / (2 * mass);
        const rate = gamma <= omega ? gamma : gamma - Math.sqrt(gamma * gamma - omega * omega);
        return rate > 0 ? Math.round(Math.log(1000) / rate * 1000 * root.motion) : 0;
    }

    // ...and its curve, as Qt's easing takes one: the two control points and
    // the end. A spring asked for where only a bezier will do is drawn as
    // the ease-out it most looks like.
    function bezier(leaf: string): var {
        const curve = root.curveOf(leaf);
        if (curve?.type !== "bezier")
            return [0.23, 1, 0.32, 1, 1, 1];

        const p = curve.points;
        return [p[0][0], p[0][1], p[1][0], p[1][1], 1, 1];
    }

    // The page comes in a section at a time as the sheet unfolds, each a beat
    // after the one above it, rising into place from this far below where it
    // rests — see `Notch.cascade`.
    readonly property int cascadeStep: 30 * root.motion
    readonly property int riseDistance: root.space3
    // How far a page travels when you step into a panel, or back out of one:
    // a fifth of the sheet, the way hyprland slides one workspace out and the
    // next one in. In from the right going in and from the left coming back,
    // so the two read as one movement and its return.
    readonly property int stepDistance: Math.round(root.expandedWidth / 5)
    // what a control is drawn at while it is held down, so a press is felt
    // as well as seen
    readonly property real pressScale: 0.92
    // one turn of a spinner: not scaled, a spinner that does not spin is a
    // spinner that has stopped
    readonly property int spinDuration: 900
    // how long the volume reading stays out after the last key press
    readonly property int osdHold: 1500
    // how long the pill stays out when it is brought out for a glance at the
    // clock — see `Notch.peek`
    readonly property int peekHold: 2500
    // How long a level meter takes to glide from one sample to the next. A
    // signal is sampled a few times a second, and a bar that stepped between
    // them would flicker; a longer glide would lag the sound it reads.
    readonly property int meterDuration: 60 * root.motion
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

    // The colour arithmetic lives in Paint, so a Scheme can be built out of
    // it while this is still being built; these hand on to it, for a page
    // that only has Theme to hand.
    function mix(a: color, b: color, t: real): color {
        return Paint.mix(a, b, t);
    }

    function clear(c: color): color {
        return Paint.clear(c);
    }

    function luminance(c: color): real {
        return Paint.luminance(c);
    }
}
