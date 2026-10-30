pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.util
import qs.widgets
import qs.notch.panels

// The shell, one instance per monitor.
//
// A notch hanging from the top edge of the screen, like the one on a macbook
// display. It is put away by default — the screen belongs to the windows on
// it — and slides back out when the pointer reaches the top edge; clicking it
// unfolds it into a panel. Unfolded, it stays: the pointer leaving is not a
// dismissal, and it takes a click outside or escape to put it away.
//
// Nothing here reserves space. The notch is not there most of the time, and
// when it is it opens over whatever is underneath rather than pushing it
// down, so it never reflows the windows behind it.
//
// The window itself covers the whole screen and is masked down to the slab
// and the strip it listens on, so every pixel the notch is not currently
// using belongs to the desktop. Open, the mask takes the whole screen
// instead — it has to, to hear the click that closes it. The window never
// changes size: a resize is a round trip to the compositor and a new buffer,
// and it would land on the first frame of every unfold and every fold.
PanelWindow {
    id: root

    required property var modelData

    // Out of the top edge, but still folded up: the pill.
    property bool revealed: false
    property bool expanded: false
    // which panel the unfolded slab is showing
    property string panel: "home"
    // out for a moment on request, without a pointer anywhere near it
    property bool held: false
    // Closed with the pointer nowhere near it, and on its way off the top
    // edge still at full size — see `onExpandedChanged`.
    property bool folding: false

    // What the slab is drawn as, which lags `expanded` by one case: a notch
    // that is being put away from the keyboard keeps its size while it
    // slides off, and only collapses once it is out of sight.
    readonly property bool unfolded: root.expanded || root.folding

    // The pointer is on the notch, or would be if it were out. A notch that
    // is closed without this folds all the way away in one movement rather
    // than shrinking to a pill nobody is there to look at.
    readonly property bool pointed: hot.hovered || hover.hovered || root.held

    // A sub-panel is a place you went to on purpose, so stepping out of it
    // returns to the home panel rather than putting the whole notch away.
    readonly property bool pinned: root.panel !== "home"

    // The notch has a reason to be on screen: the pointer is at the top edge
    // or on the notch itself, or it is open. A notification is not one of
    // them — it is announced under the top edge without the notch coming out
    // to carry it. `revealed` follows this, but lagged by the timers below,
    // so a pointer crossing the top edge does not flick it in and out.
    readonly property bool wanted: hot.hovered || hover.hovered || root.expanded || root.held

    // How tall a panel may make itself: enough for the unfolded notch to
    // cover half the screen, and no more. A panel with a list in it grows the
    // slab until it reaches this and scrolls from there, so how much of the
    // desktop the notch is willing to take is a property of the screen it is
    // on rather than a number picked in the theme.
    readonly property int bodyMaxHeight: Math.round(root.modelData.height / 2) - Theme.pagePadding * 2

    // One step back out: a sub-panel returns to the home panel, and the home
    // panel folds the notch up.
    function dismiss(): void {
        if (root.pinned)
            root.panel = "home";
        else
            root.expanded = false;
    }

    // Take the keyboard back from a panel that had borrowed it, so escape
    // still steps out once whatever was being typed into has gone.
    function takeKeys(): void {
        keys.forceActiveFocus();
    }

    // Unfold straight to a panel, from wherever the notch currently is: put
    // away, out, or already open on something else.
    //
    // Put away, the slab grows to full size while it is still off screen —
    // nothing animates up there — and then the whole panel slides down out
    // of the top edge in one movement. Out already, it unfolds in place.
    //
    // Unfolded before the page is set: unfolding takes the keyboard for the
    // notch itself — see `onExpandedChanged` — and a page with a field of
    // its own takes it from there as it is built, not the other way round.
    function open(name: string): void {
        root.expanded = true;
        root.panel = name;
        root.revealed = true;
    }

    // ...and the other way. Closed with the pointer on it, the slab shrinks
    // back to the pill under the pointer. Closed from the keyboard, or by a
    // click somewhere else, there is nobody at the top edge for a pill to
    // wait for, so it slides off at full size and collapses once hidden.
    onExpandedChanged: {
        if (root.expanded) {
            // opened again on its way off the top edge: it is not folding any more
            root.folding = false;
            keys.forceActiveFocus();
            // Unfolding in place from the pill, the page cascades in under
            // it, once the page it is opening on has been chosen — see
            // `open`. Coming out of the top edge, it rides down already
            // there, as part of the one movement.
            if (slab.slide < 0.5)
                Qt.callLater(root.cascade);
            return;
        }

        // it collapses once it is out of sight — see `sliding`
        if (!root.pointed) {
            root.folding = true;
            root.revealed = false;
        }
    }

    onPanelChanged: root.turn()

    // Show the page `panel` names. On a sheet that is all there the old page
    // is seen going as the new one comes in — see `pageTurn`; anywhere else
    // there is nothing to see go, and the page is swapped where it is.
    function turn(): void {
        // a turn still under way is finished first, so two never share a page
        pageTurn.complete();

        const component = root.panels[root.panel] ?? homePanel;
        const leaving = body.page;
        if (body.opacity < 1 || !leaving.item) {
            leaving.sourceComponent = component;
            return;
        }

        // the page on its way out takes no more clicks, and gives up the
        // keyboard before the one coming in takes it
        leaving.enabled = false;
        body.front = 1 - body.front;
        const arriving = body.page;
        arriving.enabled = true;
        arriving.sourceComponent = component;

        pageTurn.leaving = leaving;
        pageTurn.arriving = arriving;
        pageTurn.direction = root.panel === "home" ? -1 : 1;
        pageTurn.restart();
    }

    // The page arriving under a sheet that has just begun to unfold: each
    // section rises into place a beat after the one above it, so the page is
    // read top to bottom as it comes in rather than appearing all at once.
    // Whatever is still rising from the last time is put in place first, so
    // two runs never fight over a section.
    property var rising: []

    function cascade(): void {
        for (const running of root.rising)
            running?.complete();
        root.rising = [];

        const page = body.page.item;
        if (!page || Theme.motion === 0)
            return;

        let turn = 0;
        for (const section of page.children) {
            // a repeater, a timer, a section with nothing in it right now
            if (!section.visible || section.width <= 0 || section.height <= 0)
                continue;

            root.rising.push(rise.createObject(section, {
                section: section,
                delay: Theme.cascadeStep * turn++
            }));
        }
    }

    Component {
        id: rise

        Rise {}
    }

    // Bring the pill out for a moment without opening it — a glance at the
    // clock from the keyboard.
    function peek(): void {
        root.held = true;
        peekTimer.restart();
    }

    // Announce the volume under the top edge for a moment, without bringing
    // the notch out to do it.
    function showVolume(): void {
        osd.show();
    }

    screen: root.modelData

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // the notch is transient, so it takes none of the screen away from the
    // windows underneath it — not even the height of the collapsed pill
    exclusiveZone: 0
    color: "transparent"

    // What the notch occupies: the slab — off the top of the screen, and so
    // contributing nothing, while it is put away — anything hanging below it,
    // and the strip along the top edge it listens on. The rest of this window
    // belongs to the desktop, and clicks fall straight through it.
    Region {
        id: occupied

        item: hot

        Region {
            item: slab
        }

        // the toasts, by what is in the stack rather than by the view, which
        // is taller than that — see `toasts`
        Region {
            x: toasts.x
            y: toasts.y
            width: toasts.width
            height: toasts.contentHeight
        }
    }

    // ...and what an open one occupies: everything, so that a click meant for
    // something else is a dismissal rather than a click on that something.
    Region {
        id: everywhere

        item: outside
    }

    mask: root.expanded ? everywhere : occupied

    // A named layer, so compositor rules can pick this surface out:
    // `layerrule = <rule>, shell-notch` on hyprland.
    WlrLayershell.namespace: "shell-notch"

    // Only an unfolded notch listens for keys, and then it takes them all, so
    // escape lands here no matter where the pointer went. Folded up it takes
    // none, and the keyboard belongs to whatever is behind it.
    WlrLayershell.keyboardFocus: root.expanded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // The inhibitor lives on this window because the protocol wants a
    // surface to hang it on, and this is one that is always mapped: the
    // notch is put away by being masked and moved off the top edge, never by
    // being hidden. One per monitor, which is one more than the idle daemon
    // needs, and costs nothing.
    IdleInhibitor {
        window: root
        enabled: Power.awake
    }

    FocusScope {
        id: keys

        anchors.fill: parent

        focus: true

        // the first key pressed after the notch opens is what turns the focus
        // ring on; tab then walks the page from here
        Keys.onPressed: Nav.key()
        Keys.onEscapePressed: root.dismiss()
    }

    // ── everywhere else ───────────────────────────────────────────────────

    // The rest of the screen, while the notch is open. Anything in the slab
    // that wanted the click has already had it by the time it gets here, so
    // what lands on this is either outside the slab — a dismissal — or on a
    // part of the slab that does nothing, and is swallowed.
    //
    // Declared ahead of the notch itself, and so behind all of it.
    MouseArea {
        id: outside

        anchors.fill: parent

        enabled: root.expanded
        // a click with any button is a click somewhere else
        acceptedButtons: Qt.AllButtons

        onPressed: event => {
            const p = outside.mapToItem(slab, event.x, event.y);
            if (p.x < 0 || p.y < 0 || p.x >= slab.width || p.y >= slab.height)
                root.expanded = false;
        }
    }

    // ── the top edge ──────────────────────────────────────────────────────

    // The sliver of screen a put-away notch still listens on. Reaching the
    // top edge brings it back out, wherever along that edge you got there:
    // only how far down the pointer is decides, never how far across.
    //
    // It sits under the revealed slab, which is welcome to take the hover
    // from it: either one counts as being on the notch.
    Item {
        id: hot

        readonly property alias hovered: hotHover.hovered

        anchors.left: parent.left
        anchors.right: parent.right
        y: 0

        height: Theme.revealHeight

        HoverHandler {
            id: hotHover

            onPointChanged: Nav.pointer()
        }

        // This strip is the one thing the shell occupies while it is put
        // away, so a click here is going to be swallowed whatever we do with
        // it. Opening the notch at least makes it mean something.
        TapHandler {
            enabled: !root.expanded

            onTapped: {
                root.revealed = true;
                root.expanded = true;
            }
        }
    }

    // ── under the slab ────────────────────────────────────────────────────
    //
    // The volume reading and the toasts hang off the bottom edge of the slab,
    // which put away is the top of the screen: one arriving on its own drops
    // straight out of the top edge and leaves the notch where it was. If the
    // notch does come out while one is up — because the pointer went for it —
    // they ride down ahead of it rather than being covered by it, and the
    // toasts get out of the way entirely once the panel opens.
    //
    // Declared ahead of the slab, and so behind it: something on its way out
    // from under the top edge passes behind the pill if the pill is out, the
    // way it would if it really were coming out from under it.

    // The volume, set from a media key, is announced the way a notification
    // is. The shell root decides which monitor it drops on — see `showVolume`
    // — and an open notch has its own slider in view, so it is never asked.
    Osd {
        id: osd

        anchors.horizontalCenter: parent.horizontalCenter

        // where it rests, hanging under the slab like the toasts do; put away
        // it is that plus its own height further up, off the top edge
        readonly property int rest: slab.y + slab.height + Theme.toastSpacing
        // How far the toasts have to move down to hang under it: taken from
        // where it actually is, frame by frame, so they move in lockstep with
        // it rather than on a curve of their own.
        readonly property int room: Math.max(0, osd.y + osd.height + Theme.toastSpacing - osd.rest)

        // whole pixels, or the text on it shimmers as it moves
        y: Math.round(osd.rest - osd.slide * (osd.rest + osd.height))

        icon: Icons.volume(Audio.volume, Audio.muted)
        value: Audio.muted ? 0 : Audio.volume
        // a muted output draws an empty track, and the figure has to agree
        text: Audio.muted ? "Muted" : Fmt.percent(Audio.volume)
    }

    // A list rather than a column so that a toast can be seen leaving: the
    // view keeps a delegate alive until its exit has played, where a column
    // would drop it the moment it left the model.
    ListView {
        id: toasts

        anchors.horizontalCenter: parent.horizontalCenter
        // slab.y is -slab.height while the notch is put away, so this is the
        // top of the screen until the notch slides out from over it, and the
        // volume pill pushes them further down while it is out
        y: Math.round(slab.y + slab.height) + Theme.toastSpacing + osd.room

        width: Theme.toastWidth
        // As tall as there is screen for it: the view keeps a toast on for
        // its exit only while it is inside the view, and a view sized to its
        // contents has already shrunk out from under it by then. The mask
        // takes the height of what is actually there — see `occupied`.
        height: Theme.windowHeight
        spacing: Theme.toastSpacing

        // it is a stack, not a scroller: no flicking, no wheel
        interactive: false

        // Diffed against what is already there, so a notification arriving
        // or leaving touches only its own toast. A plain array would rebuild
        // every one of them — restarting their clocks, reloading their icons
        // — each time the list changed.
        model: ScriptModel {
            values: root.expanded ? [] : Notifs.toasts
        }

        delegate: Toast {
            required property var modelData

            width: ListView.view.width
            notification: modelData
        }

        // A new one drops out of the top edge — from behind the pill, if the
        // pill is out — to where it hangs, fading in as it comes.
        add: Transition {
            id: arrive

            Slide {
                property: "y"
                // Read off the transition itself: written unqualified, the
                // attached property belongs to this animation, and the view
                // fills in only the transition's. The item is there only once
                // it is running; the binding is first evaluated well before.
                from: arrive.ViewTransition.item ? arrive.ViewTransition.destination.y - arrive.ViewTransition.item.height - toasts.y : 0
            }

            Fade {
                property: "opacity"
                from: 0
                to: 1
            }
        }

        // ...and one leaving fades where it is.
        remove: Transition {
            Fade {
                leaf: "fadeOut"
                property: "opacity"
                to: 0
            }
        }

        // The rest move the way hyprland moves a layer: down in step with a
        // new one dropping in above them...
        displaced: Transition {
            Slide {
                leaf: "layers"
                property: "y"
            }
        }

        // ...and back up over the gap one leaving has left, but only once it
        // has gone, rather than up through it while it is still fading.
        removeDisplaced: Transition {
            SequentialAnimation {
                PauseAnimation {
                    duration: Theme.duration("fadeOut")
                }

                Slide {
                    leaf: "layers"
                    property: "y"
                }
            }
        }
    }

    // ── the slab ──────────────────────────────────────────────────────────

    // What lifts the slab off the window it has opened over. It fills the
    // slab and slides with it, but is pulled up by the radius of its own top
    // corners: the slab's are square and just off the top of the screen, and
    // this puts the rounded ones off it too, leaving a straight edge along
    // the top rather than a pair of curves below it.
    Shadow {
        target: slab
        radius: slab.bottomLeftRadius

        anchors.topMargin: -slab.bottomLeftRadius

        // Put away, the slab's bottom edge is exactly the top of the screen
        // and its shadow would stay behind as a band across it, so it fades
        // out over the slide instead of following it up.
        opacity: Math.max(0, Math.min(1, 1 - slab.slide))
    }

    ClippingRectangle {
        id: slab

        anchors.horizontalCenter: parent.horizontalCenter

        // How far off the top edge it is, as a fraction of its own height:
        // out is 0, put away is 1. The slide is animated on this rather
        // than on `y` itself so that a slab changing size while it is put
        // away stays put away — its `y` follows the new height at once,
        // and only a change in `revealed` sets it moving.
        readonly property alias slide: sliding.value

        // The pill's width, which the unfold is measured from.
        readonly property int pillWidth: collapsed.implicitWidth + Theme.collapsedPadding * 2
        // How far the slab has unfolded, from the pill at 0 to the sheet at
        // 1, by its width — which, unlike its height, is the same whatever
        // page it is unfolding to. What the slab carries is faded on this
        // rather than on a clock of its own, so it follows the slab wherever
        // the slab is: reached for and abandoned half way, the pill and the
        // page are each exactly as far in or out as the slab is open.
        readonly property real unfold: Math.max(0, Math.min(1, (slab.width - slab.pillWidth) / (Theme.expandedWidth - slab.pillWidth)))

        // Coming out and going back the way hyprland moves a window, and
        // growing and shrinking the way it opens one. Sent the other way
        // half way there — reached for and left, opened and closed again —
        // it turns round with the speed it had rather than stopping dead.
        //
        // The slab only changes size on a spring while it is on screen. Put
        // away, a change of size is a change nobody can see, and animating it
        // would leave the slab mid-resize when it next slides out.
        Spring {
            id: sliding

            to: root.revealed ? 0 : 1

            // gone off the top edge at full size; it can collapse to the pill
            // now without anyone seeing it happen
            onArrived: {
                if (!root.revealed)
                    root.folding = false;
            }
        }

        Spring {
            id: widening

            leaf: "windows"
            enabled: root.revealed
            to: root.unfolded ? Theme.expandedWidth : slab.pillWidth
        }

        Spring {
            id: deepening

            leaf: "windows"
            enabled: root.revealed
            to: root.unfolded ? body.height + Theme.pagePadding * 2 : Theme.collapsedHeight
        }

        // Revealed it grows out of the top edge, so the top corners are
        // square and stand on the edge itself: what shows is the slab's sides
        // and bottom, and the ears either side of it. Put away it is its own
        // height further up, entirely off the screen. In whole pixels, all of
        // it, or its edge and the text on it shimmer as it moves.
        y: Math.round(-slab.slide * slab.height)

        width: Math.round(widening.value)
        height: Math.round(deepening.value)

        topLeftRadius: 0
        topRightRadius: 0
        // The hardware notch's corners while it is the pill, rounding out
        // into the island's as it unfolds, on the same measure everything it
        // carries is faded on; capped so the corners never meet in the middle
        // of a short notch.
        bottomLeftRadius: Math.min(Theme.notchRadius + (Theme.notchRadiusOpen - Theme.notchRadius) * slab.unfold, height / 2)
        bottomRightRadius: bottomLeftRadius
        color: Theme.slab

        HoverHandler {
            id: hover

            onPointChanged: Nav.pointer()
        }

        // The collapsed pill is one big button. Once it is open the taps
        // belong to whatever is under them, and so does this one: the dots
        // are items in front of this handler, so clicking a workspace
        // switches to it instead of unfolding the notch.
        TapHandler {
            enabled: !root.expanded

            onTapped: root.expanded = true
        }

        // ── collapsed ─────────────────────────────────────────────────────

        RowLayout {
            id: collapsed

            anchors.centerIn: parent

            spacing: Theme.collapsedSpacing

            // Whichever way the notch is going, the slab moves first and what
            // it carries follows: the pill's contents are gone by the time it
            // is a fifth of the way open, and come back only once it has
            // closed that far over them again. Off screen the slab changes
            // size at once, so it slides out already carrying the right thing.
            opacity: Math.max(0, 1 - slab.unfold * 5)
            // Put away all the way, nothing on it can be seen either, and the
            // dots changing workspace are not to be animated up there.
            visible: opacity > 0 && slab.slide < 1

            Dots {
                Layout.alignment: Qt.AlignVCenter

                screen: root.modelData
            }

            // The clock is the only thing on the pill that is read rather
            // than counted, and it is read at a glance from wherever you
            // happen to be sitting: the display cut, and tabular figures so
            // the minute turning over does not shove the dots along.
            Num {
                Layout.alignment: Qt.AlignVCenter

                text: Time.time
                color: Theme.text

                font.family: Theme.displayFamily
                font.pixelSize: Theme.fontTitle
                font.weight: Font.Medium
            }

            // Something playing widens the pill by the bars at its trailing
            // end, the way a live activity widens the island, and the slab
            // grows to take them on its spring.
            Wave {
                Layout.alignment: Qt.AlignVCenter

                visible: Media.playing
                playing: Media.playing && collapsed.visible
            }
        }

        // ── expanded ──────────────────────────────────────────────────────
        //
        // Laid out at the full expanded width from the start and revealed by
        // the slab growing over it, rather than reflowing on every frame of
        // the animation.

        Item {
            id: body

            // Two pages, so that the one being left can be seen going while
            // the one stepped to comes in — see `turn`. `front` is the one
            // showing `panel`, and the sheet is as tall as it is.
            property int front: 0
            readonly property Loader page: body.front === 0 ? first : second

            // whole pixels, or the text on it shimmers as the slab grows
            x: Math.round((slab.width - width) / 2)
            y: Theme.pagePadding

            width: Theme.expandedWidth - Theme.pagePadding * 2
            height: body.page.height

            // ...and the page is the other half of that: it arrives once the
            // slab is a fifth of the way open, and is all there by two thirds,
            // so it is never seen squeezed; and going, it is gone by then.
            opacity: Math.max(0, Math.min(1, (slab.unfold - 0.2) / 0.45))
            // There from the moment the sheet starts to unfold rather than
            // from the first frame of the fade, so the cascade can tell the
            // sections that are hidden from the ones that are only waiting
            // to be shown.
            visible: root.unfolded || opacity > 0

            Loader {
                id: first

                // how far to the side it is on its way in or out, put on
                // whole pixels so the text on it holds still
                property real shift: 0

                x: Math.round(shift)
                width: parent.width

                sourceComponent: homePanel
            }

            Loader {
                id: second

                property real shift: 0

                x: Math.round(shift)
                width: parent.width
            }
        }

        // Stepping from one page to another on a sheet that is all there:
        // the way hyprland changes workspace, the page being left slides a
        // fifth of the way out and fades, while the one stepped to slides in
        // after it and comes up — from the right into a panel, and from the
        // left back home.
        ParallelAnimation {
            id: pageTurn

            property Loader leaving: null
            property Loader arriving: null
            // 1 forward into a panel, -1 back home
            property int direction: 1

            // the page left behind goes, and gives up its place
            onStopped: {
                const leaving = pageTurn.leaving;
                pageTurn.leaving = null;
                if (!leaving || leaving === body.page)
                    return;

                // A page with a field hands the keyboard back to the notch as
                // it goes — see `takeKeys` — which by now is after the page
                // coming in has taken it; it gets it back.
                const keys = body.page.activeFocus;
                leaving.sourceComponent = undefined;
                leaving.shift = 0;
                leaving.opacity = 1;
                if (keys)
                    body.page.forceActiveFocus();
            }

            Slide {
                leaf: "workspaces"
                target: pageTurn.leaving
                property: "shift"
                from: 0
                to: -pageTurn.direction * Theme.stepDistance
            }

            Fade {
                leaf: "fadeOut"
                target: pageTurn.leaving
                property: "opacity"
                to: 0
            }

            Slide {
                leaf: "workspaces"
                target: pageTurn.arriving
                property: "shift"
                from: pageTurn.direction * Theme.stepDistance
                to: 0
            }

            Fade {
                target: pageTurn.arriving
                property: "opacity"
                from: 0
                to: 1
            }
        }

        // the one tooltip, over everything on the page
        Tooltip {}
    }

    // The ears either side of the slab, flaring its sides out into the top
    // edge. They stand on the edge itself, against the straight part of the
    // slab's sides, and shrink with what is left of that as the slab slides
    // away. Once only its rounded bottom corners are still below the edge,
    // its sides curve in away from where an ear would stand, so by then the
    // ears are gone rather than left beside a gap with the desktop in it.
    readonly property int earReach: Math.max(0, Math.min(Theme.earRadius, slab.y + slab.height - slab.bottomLeftRadius))

    Ear {
        x: slab.x - root.earReach
        y: 0
        width: root.earReach
        height: root.earReach

        visible: root.earReach > 0
    }

    Ear {
        x: slab.x + slab.width
        y: 0
        width: root.earReach
        height: root.earReach

        visible: root.earReach > 0
        mirror: true
    }

    // ── revealing and unfolding ───────────────────────────────────────────

    Timer {
        id: peekTimer

        interval: 2500

        onTriggered: root.held = false
    }

    Timer {
        interval: Theme.hoverDelay
        running: root.wanted && !root.revealed

        onTriggered: root.revealed = true
    }

    Timer {
        interval: Theme.collapseDelay
        // a drag that has left the notch is still a drag
        running: !root.wanted && root.revealed && !Pointer.dragging

        onTriggered: root.revealed = false
    }

    // Back to the home panel once it has folded up, not while it is folding:
    // swapping the contents mid-animation is visible.
    Timer {
        interval: Theme.duration("windows")
        running: !root.unfolded && root.panel !== "home"

        onTriggered: root.panel = "home"
    }

    // ── the panels ────────────────────────────────────────────────────────
    //
    // By the name `open` and the ipc call them by.

    readonly property var panels: ({
            home: homePanel,
            notifications: notificationsPanel,
            audio: audioPanel,
            bluetooth: bluetoothPanel,
            network: networkPanel,
            resources: resourcesPanel
        })

    Component {
        id: homePanel

        HomePanel {
            notch: root
        }
    }

    Component {
        id: notificationsPanel

        NotificationsPanel {
            notch: root
        }
    }

    Component {
        id: audioPanel

        AudioPanel {
            notch: root
        }
    }

    Component {
        id: bluetoothPanel

        BluetoothPanel {
            notch: root
        }
    }

    Component {
        id: networkPanel

        NetworkPanel {
            notch: root
        }
    }

    Component {
        id: resourcesPanel

        ResourcesPanel {
            notch: root
        }
    }
}
