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
// The window itself is as tall as the tallest thing it can ever show and
// masked down to the slab and the strip it listens on, so every pixel the
// notch is not currently using belongs to the desktop. Open, it takes the
// whole screen instead — it has to, to hear the click that closes it.
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

    // How long the slab takes to slide out of, or back into, the top edge:
    // quick for the pill, which arrives under a pointer already moving, and
    // the unfold's own duration for the whole panel, which has further to go.
    readonly property int slideDuration: root.unfolded ? Theme.expandDuration : Theme.revealDuration

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
    readonly property int bodyMaxHeight: Math.round(root.modelData.height / 2) - Theme.expandedPadding * 2 - slab.border.width

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
    function open(name: string): void {
        root.panel = name;
        root.expanded = true;
        root.revealed = true;
    }

    // ...and the other way. Closed with the pointer on it, the slab shrinks
    // back to the pill under the pointer. Closed from the keyboard, or by a
    // click somewhere else, there is nobody at the top edge for a pill to
    // wait for, so it slides off at full size and collapses once hidden.
    onExpandedChanged: {
        if (root.expanded) {
            keys.forceActiveFocus();
            return;
        }

        if (!root.pointed) {
            root.folding = true;
            root.revealed = false;
            foldTimer.restart();
        }
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
        // An open notch has to hear a click anywhere on the screen to know it
        // has been dismissed, so it takes the whole screen while it is open
        // and shrinks back to the strip along the top when it folds up.
        bottom: root.expanded
    }

    implicitHeight: Theme.windowHeight
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

    FocusScope {
        id: keys

        anchors.fill: parent

        focus: true

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
                property: "opacity"
                to: 0
            }
        }

        // The rest move on the curve the slab moves on: down in step with a
        // new one dropping in above them...
        displaced: Transition {
            Slide {
                property: "y"
            }
        }

        // ...and back up over the gap one leaving has left, but only once it
        // has gone, rather than up through it while it is still fading.
        removeDisplaced: Transition {
            SequentialAnimation {
                PauseAnimation {
                    duration: Theme.fadeDuration
                }

                Slide {
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
        opacity: root.revealed ? 1 : 0

        Behavior on opacity {
            Fade {
                duration: root.slideDuration
            }
        }
    }

    ClippingRectangle {
        id: slab

        anchors.horizontalCenter: parent.horizontalCenter

        // How far off the top edge it is, as a fraction of its own height:
        // out is 0, put away is 1. The slide is animated on this rather
        // than on `y` itself so that a slab changing size while it is put
        // away stays put away — its `y` follows the new height at once,
        // and only a change in `revealed` sets it moving.
        property real slide: root.revealed ? 0 : 1

        Behavior on slide {
            Slide {
                duration: root.slideDuration
            }
        }

        // Revealed it grows out of the top edge, so the top corners are
        // square and the top border is pushed just off screen: what shows is
        // the slab's sides and bottom, and nothing else. Put away it is that
        // much further up, entirely off the screen.
        y: -border.width - slab.slide * (slab.height - border.width)

        width: root.unfolded ? Theme.expandedWidth : collapsed.implicitWidth + Theme.collapsedPadding * 2
        height: border.width + (root.unfolded ? body.height + Theme.expandedPadding * 2 : Theme.collapsedHeight)

        topLeftRadius: 0
        topRightRadius: 0
        // capped so the corners never meet in the middle of a short notch
        bottomLeftRadius: Math.min(Theme.slabRadius, height / 2)
        bottomRightRadius: bottomLeftRadius
        color: Theme.slab

        border.width: 1
        border.color: Theme.slabBorder

        // The slab only animates its size while it is on screen. Put away,
        // a change of size is a change nobody can see, and animating it
        // would leave the slab mid-resize when it next slides out.
        Behavior on width {
            enabled: root.revealed

            Slide {}
        }

        Behavior on height {
            enabled: root.revealed

            Slide {}
        }

        HoverHandler {
            id: hover
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

            // centred in the visible part, not counting the hidden top border
            anchors.centerIn: parent
            anchors.verticalCenterOffset: slab.border.width / 2

            spacing: Theme.collapsedSpacing

            opacity: root.unfolded ? 0 : 1
            visible: opacity > 0

            // Whichever way the notch is going, the slab moves first and what
            // it carries follows: the pill's contents leave the moment it
            // starts to unfold, and come back only once it has closed most of
            // the way over them again. Off screen there is no crossfade
            // to see, so the swap is made at once and the slab slides out
            // already carrying the right thing.
            Behavior on opacity {
                enabled: root.revealed

                SequentialAnimation {
                    PauseAnimation {
                        duration: root.unfolded ? 0 : Theme.staggerDelay
                    }

                    Fade {}
                }
            }

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
                font.pixelSize: Theme.fontClock
                font.weight: Font.Medium
            }
        }

        // ── expanded ──────────────────────────────────────────────────────
        //
        // Laid out at the full expanded width from the start and revealed by
        // the slab growing over it, rather than reflowing on every frame of
        // the animation.

        Item {
            id: body

            x: (slab.width - width) / 2
            y: slab.border.width + Theme.expandedPadding

            width: Theme.expandedWidth - Theme.expandedPadding * 2
            height: loader.height

            opacity: root.unfolded ? 1 : 0
            visible: opacity > 0

            // ...and the panel is the other half of that: it waits for the
            // slab to be most of the way open before it arrives, and is gone
            // before the slab starts to close.
            Behavior on opacity {
                enabled: root.revealed

                SequentialAnimation {
                    PauseAnimation {
                        duration: root.unfolded ? Theme.staggerDelay : 0
                    }

                    Fade {}
                }
            }

            Loader {
                id: loader

                width: parent.width

                sourceComponent: root.panels[root.panel] ?? homePanel

                // the slab is already animating its height; fading the new
                // panel in over that is what keeps the swap from snapping
                onLoaded: swap.restart()

                Fade on opacity {
                    id: swap

                    from: 0
                    to: 1
                }
            }
        }
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

    // The slab sliding off the top edge at full size; once it is gone it can
    // collapse to the pill without anyone seeing it happen.
    Timer {
        id: foldTimer

        interval: Theme.expandDuration

        onTriggered: root.folding = false
    }

    // Back to the home panel once it has folded up, not while it is folding:
    // swapping the contents mid-animation is visible.
    Timer {
        interval: Theme.expandDuration
        running: !root.unfolded && root.pinned

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
