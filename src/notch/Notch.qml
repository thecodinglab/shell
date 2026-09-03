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

    // A sub-panel is a place you went to on purpose, so stepping out of it
    // returns to the home panel rather than putting the whole notch away.
    readonly property bool pinned: root.panel !== "home"

    // The notch has a reason to be on screen: the pointer is at the top edge
    // or on the notch itself, or it is open. A notification is not one of
    // them — it is announced under the top edge without the notch coming out
    // to carry it. `revealed` follows this, but lagged by the timers below,
    // so a pointer crossing the top edge does not flick it in and out.
    readonly property bool wanted: hot.hovered || hover.hovered || root.expanded

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

        Region {
            item: toasts
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

    onExpandedChanged: if (root.expanded)
        keys.forceActiveFocus()

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
            NumberAnimation {
                duration: Theme.revealDuration
            }
        }
    }

    ClippingRectangle {
        id: slab

        anchors.horizontalCenter: parent.horizontalCenter

        // Revealed it grows out of the top edge, so the top corners are
        // square and the top border is pushed just off screen: what shows is
        // the slab's sides and bottom, and nothing else. Put away it is that
        // much further up, entirely off the screen.
        y: root.revealed ? -border.width : -slab.height

        Behavior on y {
            NumberAnimation {
                duration: Theme.revealDuration
                easing.type: Theme.expandEasing
            }
        }

        width: root.expanded ? Theme.expandedWidth : collapsed.implicitWidth + Theme.collapsedPadding * 2
        height: border.width + (root.expanded ? body.height + Theme.expandedPadding * 2 : Theme.collapsedHeight)

        topLeftRadius: 0
        topRightRadius: 0
        // capped so the corners never meet in the middle of a short notch
        bottomLeftRadius: Math.min(Theme.slabRadius, height / 2)
        bottomRightRadius: bottomLeftRadius
        color: root.expanded ? Theme.slab : Theme.slabCollapsed

        border.width: 1
        border.color: Theme.slabBorder

        Behavior on width {
            NumberAnimation {
                duration: Theme.expandDuration
                easing.type: Theme.expandEasing
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Theme.expandDuration
                easing.type: Theme.expandEasing
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Theme.expandDuration
            }
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

            opacity: root.expanded ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.fadeDuration
                }
            }

            Dots {
                Layout.alignment: Qt.AlignVCenter

                screen: root.modelData
            }

            Mono {
                Layout.alignment: Qt.AlignVCenter

                text: Time.time
                color: Theme.text

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

            opacity: root.expanded ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.fadeDuration
                }
            }

            Loader {
                id: loader

                width: parent.width

                sourceComponent: {
                    switch (root.panel) {
                    case "bluetooth":
                        return bluetoothPanel;
                    case "audio":
                        return audioPanel;
                    case "resources":
                        return resourcesPanel;
                    default:
                        return homePanel;
                    }
                }

                // the slab is already animating its height; fading the new
                // panel in over that is what keeps the swap from snapping
                onLoaded: swap.restart()

                NumberAnimation on opacity {
                    id: swap

                    from: 0
                    to: 1
                    duration: Theme.fadeDuration
                }
            }
        }
    }

    // ── notifications ─────────────────────────────────────────────────────
    //
    // They hang off the bottom edge of the slab, which put away is the top of
    // the screen: one arriving on its own drops straight out of the top edge
    // and leaves the notch where it was. If the notch does come out while a
    // toast is up — because the pointer went for it — they ride down ahead of
    // it rather than being covered by it, and get out of the way entirely
    // once the panel opens.

    Column {
        id: toasts

        anchors.horizontalCenter: parent.horizontalCenter
        // slab.y is -slab.height while the notch is put away, so this is the
        // top of the screen until the notch slides out from over it
        y: slab.y + slab.height + Theme.toastSpacing

        width: Theme.toastWidth
        spacing: Theme.toastSpacing

        Repeater {
            model: root.expanded ? [] : Notifs.toasts

            Toast {
                required property var modelData

                width: toasts.width
                notification: modelData
            }
        }
    }

    // ── revealing and unfolding ───────────────────────────────────────────

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
        interval: Theme.expandDuration
        running: !root.expanded && root.panel !== "home"

        onTriggered: root.panel = "home"
    }

    Component {
        id: homePanel

        HomePanel {
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
        id: audioPanel

        AudioPanel {
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
