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

    // the power mark on the home page was pressed, for the shell root to
    // bring the power pane out on this monitor
    signal powerRequested

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

    // How tall a page may make itself: enough for the unfolded notch to
    // cover half the screen, and no more, so how much of the desktop the
    // notch is willing to take is a property of the screen it is on rather
    // than a number picked in the theme.
    readonly property int bodyMaxHeight: Math.round(root.modelData.height / 2) - Theme.pagePadding * 2

    // How tall the page in front would have the sheet: as tall as it is, up
    // to the most it may be.
    readonly property int naturalHeight: Math.min((body.page.item as Item)?.implicitHeight ?? 0, root.bodyMaxHeight)

    // The sheet takes its size from each page as the page comes in — as the
    // notch opens, and stepping from one page to another — and then holds
    // it for as long as that page is open. Nothing on the page moves the
    // sheet under the pointer once it is there: a list filling up scrolls
    // rather than growing it, a second player turning up scrolls the page,
    // and something going leaves its room where it was.
    //
    // It is held once the page has had a moment to come in, so the sheet
    // follows the page as it arrives and settles with it.
    property bool holding: false
    property int heldHeight: 0
    readonly property int bodyHeight: root.holding ? root.heldHeight : root.naturalHeight
    // The room a page has to fill: the height it is held at, or the most it
    // may have while it is still coming in. A list sizes itself from this.
    readonly property int pageRoom: root.holding ? root.heldHeight : root.bodyMaxHeight

    // let go, and take the size again once the page is in
    function settle(): void {
        root.holding = false;
        settling.restart();
    }

    Timer {
        id: settling

        interval: Theme.duration("windows")

        onTriggered: {
            if (!root.unfolded)
                return;
            root.heldHeight = root.naturalHeight;
            root.holding = true;
        }
    }

    // What floats over the page rather than being laid out on it — a pop-up
    // menu, say — is put in here, over the open sheet and under the tooltip,
    // so it neither moves the page nor is cut off by it.
    readonly property Item overlay: overlayLayer

    // One step back out: a sub-panel returns to the home panel, and the home
    // panel folds whatever it has open in place, and then the notch.
    function dismiss(): void {
        const home = body.page.item as HomePanel;
        if (home && home.back())
            return;
        if (root.pinned)
            root.panel = "home";
        else
            root.expanded = false;
    }

    // Scroll whatever `item` scrolls in — the page, or a menu floating over
    // it — just far enough to show it, if that scrolls at all.
    function reveal(item: Item): void {
        if (!item)
            return;

        let view = null;
        for (let p = item.parent; p && !view; p = p.parent)
            view = p as Flickable;
        if (!view || !view.interactive)
            return;

        const top = item.mapToItem(view.contentItem, 0, 0).y;
        if (top < view.contentY)
            view.contentY = top;
        else if (top + item.height > view.contentY + view.height)
            view.contentY = Math.min(top + item.height - view.height, view.contentHeight - view.height);
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
            // and whatever has changed on the page while it was put away,
            // it is measured afresh
            root.settle();
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
        root.settle();

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

        const page = body.page.item as Item;
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

    // ...and a bluetooth device's connection moving, the same way.
    readonly property bool hailing: hail.shown

    function showDevice(device: var, failed: bool): void {
        hail.show(device, failed);
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

        // the toasts, by the stack that holds them, which clips them to as
        // much of them as is out
        Region {
            item: stack
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
    // none, and the keyboard belongs to whatever is behind it. While a
    // password is being asked for the keyboard is the polkit pane's, and a
    // notch unfolded with the pointer meanwhile waits for it to be done.
    WlrLayershell.keyboardFocus: root.expanded && !Polkit.flow ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
    // The notifications are more of the notch: a stack of the bezel hanging
    // from the top edge with ears of its own, behind the slab and the tally,
    // so that whichever of them is out is part of it rather than over it.
    // The volume reading is glass, and hangs under all of it. If the notch
    // comes out while a notification is up — because the pointer went for
    // it — the stack deepens by as much as the pill reaches down, and the
    // toasts get out of the way entirely once the panel opens.
    //
    // Declared ahead of the slab, and so behind it: something on its way out
    // from under the top edge passes behind the pill if the pill is out, the
    // way it would if it really were coming out from under it.

    // The volume, set from a media key, is announced under the top edge
    // without the notch. The shell root decides which monitor it drops on —
    // see `showVolume` — and an open notch has its own slider in view, so it
    // is never asked.
    Osd {
        id: osd

        anchors.horizontalCenter: parent.horizontalCenter

        // Where it rests, hanging under the slab — or the tally, see `hang` —
        // or under the notifications while there are any, following the foot
        // of the stack frame by frame as it deepens and gives back; put away
        // it is that plus its own height further up, off the top edge.
        readonly property int rest: Math.max(root.hang, stack.height) + Theme.toastSpacing

        // whole pixels, or the text on it shimmers as it moves
        y: Math.round(osd.rest - osd.slide * (osd.rest + osd.height))

        icon: Icons.volume(Audio.volume, Audio.muted)
        value: Audio.muted ? 0 : Audio.volume
        // a muted output draws an empty track, and the figure has to agree
        text: Audio.muted ? "Muted" : Fmt.percent(Audio.volume)
    }

    // A bluetooth device connecting or disconnecting, announced the same
    // way and on the same monitor, see `showDevice`. It hangs under the
    // volume reading while that is out, following it as it comes and goes,
    // and stays in while the notch is open, where the bluetooth mark's
    // disc and the panel already say it.
    Hail {
        id: hail

        anchors.horizontalCenter: parent.horizontalCenter

        readonly property int rest: osd.rest + Math.round(Math.max(0, 1 - osd.slide) * (osd.height + Theme.toastSpacing))

        y: Math.round(hail.rest - hail.slide * (hail.rest + hail.height))

        suppressed: root.unfolded
    }

    // ── the notifications ─────────────────────────────────────────────────

    // What should be hanging under this notch: the toasts that are up,
    // unless the panel is open, where the toasts get out of the way.
    readonly property var current: root.expanded ? [] : Notifs.toasts

    // A toast in the stack: one that is up, or one on its way out, closing
    // up where it stood. Kept here rather than left to a view, because a
    // view lets go of the place of whatever has left its model: the toast
    // on its way out stays where it was drawn while the rest close over it,
    // and stops counting toward how deep the stack is, so the stack comes
    // up short and drops back the moment it has gone.
    component Entry: QtObject {
        property var notification
        // out of `current`, and closing up before it goes
        property bool gone: false
    }

    Component {
        id: entryComponent

        Entry {}
    }

    // in the order they stand, newest at the head, the ones on their way
    // out where they were
    property var shown: []
    // the entry each notification that is up stands in
    readonly property var entries: new Map()

    // Bring `shown` in line with `current`. What has left it is marked gone
    // and keeps its place until it has closed up — see `release`; what has
    // come into it opens just above whichever of the ones after it is
    // already there, which for one arriving is the head of the stack. One
    // that comes back while it is still closing up gets a new entry, opening
    // at its new place, rather than turning round in its old one: what is on
    // its way out has stopped being a notification and is only a picture of
    // one — see Toast.freeze.
    //
    // What has left starts closing a moment later, on the same turn as what
    // has come in starts opening — see `placed` — so one pushed off the foot
    // as another opens at the head are the same spring run both ways, and the
    // stack holds its depth to the pixel while they trade places.
    function restack(): void {
        const left = [];
        for (const [notification, entry] of root.entries) {
            if (!root.current.includes(notification)) {
                left.push(entry);
                root.entries.delete(notification);
            }
        }
        if (left.length > 0)
            Qt.callLater(() => left.forEach(entry => entry.gone = true));

        const shown = [...root.shown];
        root.current.forEach((notification, i) => {
            if (root.entries.has(notification))
                return;

            const entry = entryComponent.createObject(root, {
                notification: notification
            });
            root.entries.set(notification, entry);

            let at = -1;
            for (let j = i + 1; j < root.current.length && at < 0; j++)
                at = shown.indexOf(root.entries.get(root.current[j]));
            if (at < 0)
                at = i === 0 ? 0 : shown.indexOf(root.entries.get(root.current[i - 1])) + 1;
            shown.splice(at, 0, entry);
        });
        root.shown = shown;
    }

    onCurrentChanged: root.restack()
    Component.onCompleted: root.restack()

    // An entry that has closed up, out of the stack.
    function release(entry: Entry): void {
        if (!root.shown.includes(entry))
            return;

        root.shown = root.shown.filter(e => e !== entry);
        entry.destroy();
    }

    // What lifts the stack off the window behind it, pulled up off the top
    // edge by the radius of its corners the way the slab's is.
    Shadow {
        target: stack
        radius: stack.bottomLeftRadius

        anchors.topMargin: -stack.bottomLeftRadius

        visible: stack.visible
    }

    // The notifications that are up, as one piece of the notch: the bezel,
    // square where it meets the top edge and round below, with ears where
    // its sides meet the edge. The first one to arrive grows it out of the
    // edge at the pill's width, and it widens to a notification's as it
    // deepens, its corners rounding out from the hardware notch's as it
    // goes, the way the slab unfolds into the sheet. Each one after that
    // opens at the head of it, under the edge, and pushes the rest down, so
    // the stack only ever deepens and gives back: there is never a gap in it,
    // and never more than one of it. The last one going takes it back up
    // into the edge.
    ClippingRectangle {
        id: stack

        // How far it has widened, from the pill at 0 to a notification's
        // width at 1. What it carries fades on this, the way the page fades
        // on the slab's unfold.
        readonly property real unfold: Math.max(0, Math.min(1, (stack.width - slab.pillWidth) / (Theme.toastWidth - slab.pillWidth)))
        // How much of the notifications is out, frame by frame, as each one
        // opens and closes — see the delegate.
        readonly property real fill: toasts.implicitHeight
        // The room it keeps at its head for the pill or the tally, which hang
        // in front of it from the same edge — see `hang`. Taken up only as the
        // notifications come out, so an empty stack is nothing at all rather
        // than a band either side of the pill.
        readonly property real head: Math.min(root.hang, stack.fill)

        anchors.horizontalCenter: parent.horizontalCenter
        y: 0

        // whole pixels, all of it, or its edge and the text on it shimmer
        width: Math.round(spreading.value)
        height: Math.round(stack.head + stack.fill)

        visible: stack.height > 0

        topLeftRadius: 0
        topRightRadius: 0
        // the pill's corners rounding out into a notification's, which are
        // concentric with the sender's icon, the padding in
        bottomLeftRadius: Math.min(Theme.notchRadius + (Theme.toastRadius - Theme.notchRadius) * stack.unfold, stack.height / 2)
        bottomRightRadius: stack.bottomLeftRadius
        color: Theme.bezel.ground

        // the way the notch grows, from the pill's width while it is empty
        Spring {
            id: spreading

            leaf: "windows"
            to: root.current.length > 0 ? Theme.toastWidth : slab.pillWidth
        }

        // A column of what `shown` holds, the ones on their way out among
        // them, so each closes up where it stands and counts toward the
        // depth of the stack until it has.
        Column {
            id: toasts

            // laid out at a notification's width from the start, and shown
            // by the stack widening over it from the middle, rather than
            // reflowing on every frame
            x: Math.round((stack.width - toasts.width) / 2)
            y: Math.round(stack.head)

            width: Theme.toastWidth

            // in after the stack has started to widen, and all there by two
            // thirds of the way, so it is never seen squeezed
            opacity: Math.max(0, Math.min(1, (stack.unfold - 0.2) / 0.45))

            Repeater {
                // Diffed against what is already there, so a notification
                // arriving or leaving touches only its own toast. A plain
                // array would rebuild every one of them — restarting their
                // clocks, reloading their icons — each time the list changed.
                model: ScriptModel {
                    values: root.shown
                }

                // Its place in the stack, which opens from nothing to the
                // height of the toast in it and closes back up to nothing
                // again. The toast stands on the foot of it, so as it opens
                // the toast comes down out of the top of its place — out of
                // the top edge, for the newest, from behind the pill if the
                // pill is out — and as it closes the toast goes back up into
                // it. The rest of the stack follows its foot, so they move in
                // step with it rather than on a curve of their own, and the
                // stack deepens by exactly as much. A new one opening at the
                // head as the last is pushed off the foot is the one spring
                // twice, so the stack holds its depth while they trade places.
                delegate: Item {
                    id: slot

                    required property Entry modelData
                    required property int index

                    // in the stack, and so to be opened: set a moment after
                    // it is made, so it opens from nothing rather than
                    // starting out
                    property bool placed: false
                    readonly property bool leaving: slot.modelData.gone

                    width: toasts.width
                    height: Math.round(toast.implicitHeight * Math.max(0, opening.value))

                    clip: true

                    Component.onCompleted: Qt.callLater(() => slot.placed = true)

                    // What it shows is held from the moment it leaves. With
                    // nothing of it out yet there is nothing to close up, and
                    // it goes there and then; so does one that closes with no
                    // motion at all, which the spring reports as arriving.
                    onLeavingChanged: {
                        if (!slot.leaving)
                            return;

                        toast.freeze();
                        if (!slot.placed || (opening.value <= 0 && !opening.moving))
                            Qt.callLater(() => root.release(slot.modelData));
                    }

                    // out of the top edge the way the notch comes out of it
                    Spring {
                        id: opening

                        to: slot.placed && !slot.leaving ? 1 : 0

                        onArrived: {
                            if (slot.leaving)
                                Qt.callLater(() => root.release(slot.modelData));
                        }
                    }

                    Toast {
                        id: toast

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom

                        notification: slot.modelData.notification

                        // fading as it closes up, but not as it opens: it
                        // comes out of the edge whole, the way the notch does
                        opacity: slot.leaving ? Math.max(0, Math.min(1, opening.value)) : 1
                    }

                    // in front of the toast, which slides under it
                    Rule {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.toastPadding
                        anchors.rightMargin: Theme.toastPadding
                        y: 0

                        visible: slot.index > 0
                    }
                }
            }
        }
    }

    // The stack's ears, flaring its sides out into the top edge the way the
    // slab's do, and going the same way once only its rounded corners are
    // still below the edge — see `earReach`.
    readonly property int stackEar: Math.max(0, Math.min(Theme.earRadius, stack.height - stack.bottomLeftRadius))

    Ear {
        x: stack.x - root.stackEar
        y: 0
        width: root.stackEar
        height: root.stackEar

        visible: root.stackEar > 0
    }

    Ear {
        x: stack.x + stack.width
        y: 0
        width: root.stackEar
        height: root.stackEar

        visible: root.stackEar > 0
        mirror: true
    }

    // The line round it that tells it from a dark window, as round the open
    // sheet: it hangs over the desktop as the sheet does, carrying as much.
    // It comes up as the stack widens, and is not there while the stack is
    // still no wider than the pill, which has none.
    KeyLine {
        target: stack
        radius: stack.bottomLeftRadius
        ear: root.stackEar

        opacity: stack.unfold
    }

    // ── the tally ─────────────────────────────────────────────────────────

    // What stays on the top edge of a notch that is put away while the
    // microphone, the camera or the screen is in use — see Tally. Behind the
    // slab, which covers it whenever it is out: the pill carries its own dot.
    Tally {
        id: tally

        anchors.horizontalCenter: parent.horizontalCenter
        y: 0

        covered: slab.y + slab.height >= tally.height
    }

    // The lowest edge anything hangs from at the top of the screen: the
    // slab's, or put away, the tally's while it is out. The volume reading
    // and the toasts hang under this rather than over the tally, which would
    // hide the one thing it is there to show for as long as they were up.
    readonly property int hang: Math.round(Math.max(slab.y + slab.height, tally.reach))

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
            to: root.unfolded ? root.bodyHeight + Theme.pagePadding * 2 : Theme.collapsedHeight
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
        color: Theme.bezel.ground

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

            // each one a target the full height of the pill
            Dots {
                Layout.alignment: Qt.AlignVCenter

                screen: root.modelData
                reach: (Theme.collapsedHeight - Theme.dotSize) / 2
            }

            // The clock is the only thing on the pill that is read rather
            // than counted, and it is read at a glance from wherever you
            // happen to be sitting: the display cut, and tabular figures so
            // the minute turning over does not shove the dots along.
            Num {
                Layout.alignment: Qt.AlignVCenter

                text: Time.time
                color: Theme.bezel.text

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

            // Something is using the microphone, the camera or the screen:
            // a dot at the very end, where a mac puts it beside the notch, in
            // the colour that says on — see `Scheme.privacy`. What, and who,
            // is on the page.
            Rectangle {
                Layout.alignment: Qt.AlignVCenter

                visible: Privacy.active

                implicitWidth: Theme.privacyDot
                implicitHeight: Theme.privacyDot

                radius: width / 2
                color: Theme.bezel.privacy

                Accessible.role: Accessible.Indicator
                Accessible.name: Privacy.summary
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
            // showing `panel`.
            property int front: 0
            readonly property Loader page: body.front === 0 ? first : second
            readonly property Flickable view: body.front === 0 ? firstView : secondView

            // whole pixels, or the text on it shimmers as the slab grows
            x: Math.round((slab.width - width) / 2)
            y: Theme.pagePadding

            width: Theme.expandedWidth - Theme.pagePadding * 2
            height: root.bodyHeight

            // ...and the page is the other half of that: it arrives once the
            // slab is a fifth of the way open, and is all there by two thirds,
            // so it is never seen squeezed; and going, it is gone by then.
            opacity: Math.max(0, Math.min(1, (slab.unfold - 0.2) / 0.45))
            // There from the moment the sheet starts to unfold rather than
            // from the first frame of the fade, so the cascade can tell the
            // sections that are hidden from the ones that are only waiting
            // to be shown.
            visible: root.unfolded || opacity > 0

            // Each page in a view of its own, which scrolls only when the
            // page is taller than the sheet. The view reaches out to the
            // slab's sides, so a page sliding in or out is cut off where the
            // sheet ends rather than at its margin; top and bottom it stops
            // at the page, so what scrolls goes under a margin of the sheet.
            // A page is never shorter than the view: what it does with the
            // room it has over is up to it.
            Flickable {
                id: firstView

                x: -Theme.pagePadding
                width: parent.width + Theme.pagePadding * 2
                height: parent.height

                clip: true
                contentWidth: width
                contentHeight: first.height
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: first

                    // how far to the side it is on its way in or out, put on
                    // whole pixels so the text on it holds still
                    property real shift: 0

                    x: Theme.pagePadding + Math.round(shift)
                    width: body.width
                    height: Math.max((first.item as Item)?.implicitHeight ?? 0, firstView.height)

                    sourceComponent: homePanel

                    // every page starts at its top
                    onLoaded: firstView.contentY = 0
                }
            }

            Flickable {
                id: secondView

                x: -Theme.pagePadding
                width: parent.width + Theme.pagePadding * 2
                height: parent.height

                clip: true
                contentWidth: width
                contentHeight: second.height
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: second

                    property real shift: 0

                    x: Theme.pagePadding + Math.round(shift)
                    width: body.width
                    height: Math.max((second.item as Item)?.implicitHeight ?? 0, secondView.height)

                    onLoaded: secondView.contentY = 0
                }
            }

            // How far down a page that scrolls is, in the margin beside it:
            // a band for what is in view, there only while there is more
            // than fits. It is not to be grabbed; the wheel moves the page.
            Rectangle {
                x: body.width + Math.round((Theme.pagePadding - width) / 2)
                y: Math.round(body.view.visibleArea.yPosition * body.height)

                visible: body.view.interactive

                width: Theme.scrollThickness
                height: Math.round(body.view.visibleArea.heightRatio * body.height)

                radius: width / 2
                color: Theme.bezel.track
            }

            // Whatever the keyboard reaches on a page that scrolls, or in a
            // menu that does, is brought into view, the way a list brings in
            // the row it is on.
            Connections {
                target: body.Window

                function onActiveFocusItemChanged(): void {
                    root.reveal(body.Window.activeFocusItem);
                }
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

        // what floats over the page — see `overlay`
        Item {
            id: overlayLayer

            anchors.fill: parent

            visible: body.visible
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

    // Unfolded, a line round the sheet and its ears that tells it from a
    // dark window it has opened over. It comes up as the slab unfolds and is
    // gone by the pill, which is the hardware notch and has no line round it.
    KeyLine {
        target: slab
        radius: slab.bottomLeftRadius
        ear: root.earReach

        opacity: slab.unfold
    }

    // ── revealing and unfolding ───────────────────────────────────────────

    Timer {
        id: peekTimer

        interval: Theme.peekHold

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
