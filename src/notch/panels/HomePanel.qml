pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.theme
import qs.services
import qs.util
import qs.widgets
import qs.notch

// What the notch shows when it first unfolds: the time it was already
// showing, what is playing, how loud, and four doors further in.
//
// A page rather than a stack of modules. The clock is its title, set large
// at the top left; under it the sections follow with nothing between them
// but air — what is playing, the sound, a grid of four tiles, and at the
// foot the four ways out of the session. Nothing on it has a ground of its
// own until the pointer, or the keyboard, finds it.
ColumnLayout {
    id: root

    required property var notch

    readonly property var link: Network.primary

    spacing: Theme.sectionSpacing

    // ── the head ──────────────────────────────────────────────────────────
    // The clock, grown from the pill into the page's title, with the date
    // under it; and at the right the dots where they were, and the door to
    // the notifications with a count of what is waiting on it.

    RowLayout {
        Layout.fillWidth: true

        spacing: Theme.space4

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            spacing: 0

            Num {
                Layout.fillWidth: true

                text: Time.time
                color: Theme.text

                font.family: Theme.displayFamily
                font.pixelSize: Theme.fontDisplay
                font.weight: Font.DemiBold
                font.letterSpacing: -Theme.fontDisplay * 0.03
            }

            Sans {
                Layout.fillWidth: true

                text: Time.date
                color: Theme.textMuted
            }
        }

        Dots {
            Layout.alignment: Qt.AlignVCenter

            screen: root.notch.modelData
        }

        // the bell, with the count of what is waiting on its shoulder
        Item {
            Layout.alignment: Qt.AlignVCenter

            implicitWidth: bell.implicitWidth
            implicitHeight: bell.implicitHeight

            IconButton {
                id: bell

                anchors.fill: parent

                icon: Icons.bell
                label: "Notifications"

                onClicked: root.notch.panel = "notifications"
            }

            Badge {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -Theme.space2
                anchors.rightMargin: -Theme.space2

                count: Notifs.count
            }
        }
    }

    // ── what is playing ───────────────────────────────────────────────────
    // every player that is up, whatever is playing at the top, so a paused
    // video does not vanish the moment music starts somewhere else

    Repeater {
        model: Media.players

        NowPlaying {
            required property var modelData

            Layout.fillWidth: true

            player: modelData
        }
    }

    // ── sound ─────────────────────────────────────────────────────────────
    // The head of the section names it and says where the sound is going,
    // and is the way into the panel; the bar under it is the one thing
    // worth setting without going there.

    ColumnLayout {
        Layout.fillWidth: true

        spacing: Theme.stackSpacing

        ListRow {
            id: soundHead

            Layout.fillWidth: true
            // the row's hover ground reaches out past the page margin, so
            // the name inside it stays on the grid
            Layout.topMargin: -Theme.rowPadding
            Layout.bottomMargin: -Theme.rowPadding

            bleed: true

            Accessible.name: "Sound"

            onClicked: root.notch.panel = "audio"

            Heading {
                Layout.fillWidth: true

                text: "Sound"
            }

            Caption {
                Layout.alignment: Qt.AlignVCenter

                text: Audio.sink ? Audio.label(Audio.sink) : "No output"
                color: soundHead.hovered ? Theme.textMuted : Theme.textDim
            }

            Glyph {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: -Theme.space2

                text: Icons.forward
                color: soundHead.hovered ? Theme.textMuted : Theme.textFaint

                Layout.preferredWidth: implicitWidth
                font.pixelSize: Theme.fontSmall
            }
        }

        // the bar alone: the figure is in the panel
        Volume {
            Layout.fillWidth: true

            node: Audio.sink
            figure: false
        }
    }

    // ── four tiles ────────────────────────────────────────────────────────
    // Two rows of two with a hairline between them. A lit disc means the
    // thing is in use: a device on the line, a link carrying an address.
    // A chevron means the tile is a door; a switch means it is a setting.

    GridLayout {
        Layout.fillWidth: true
        // the tiles' hover grounds reach out to the page's edges
        Layout.leftMargin: -Theme.rowPadding
        Layout.rightMargin: -Theme.rowPadding

        columns: 2
        rowSpacing: 0
        columnSpacing: Theme.space2

        Tile {
            Layout.fillWidth: true
            // both columns get half the row regardless of what is in them
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            icon: {
                if (!Bt.enabled)
                    return Icons.bluetoothOff;
                return Bt.primary ? Icons.device(Bt.primary.icon) : Icons.bluetooth;
            }
            on: Bt.primary !== null
            door: true
            rule: true
            title: "Bluetooth"
            caption: {
                if (!Bt.available)
                    return "No adapter";
                if (!Bt.enabled)
                    return "Off";
                if (Bt.primary)
                    return [Bt.label(Bt.primary), Bt.battery(Bt.primary)].filter(part => part).join(", ");
                return Bt.discovering ? "Scanning" : "Not connected";
            }

            Accessible.name: "Bluetooth"

            onClicked: root.notch.panel = "bluetooth"
        }

        Tile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            icon: root.link ? Icons.link(root.link.kind) : Icons.networkOff
            on: Network.state === "connected"
            door: true
            rule: true
            // named for what it is rather than for the setting: a machine
            // on a wire is on ethernet, not on "network"
            title: root.link ? Network.kindLabel(root.link.kind) : "Network"
            caption: {
                switch (Network.state) {
                case "connected":
                    return Network.address;
                case "linked":
                    return "No address";
                default:
                    return "Offline";
                }
            }
            captionColor: Network.state === "connected" ? Theme.textDim : Theme.urgent

            Accessible.name: "Network"

            onClicked: root.notch.panel = "network"
        }

        // The inhibitor: on, the notch holds a wayland inhibitor on its
        // window and the idle daemon neither locks the screen nor turns it
        // off; off, the daemon is left to its timeouts.
        Tile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            icon: Icons.awake
            title: "Stay awake"
            caption: Power.awake ? "Screen stays on" : "Off"

            Accessible.name: "Stay awake"

            onClicked: Power.awake = !Power.awake

            trailing: Toggle {
                checked: Power.awake
                label: "Stay awake"
                // the tile is the button; the switch only shows the state
                activeFocusOnTab: false

                onToggled: Power.awake = !Power.awake
            }
        }

        // The door to the system page. Its disc is a ring rather than a
        // glyph — how busy the processor is, read the way the dials inside
        // are read — and the line under it carries the two figures worth
        // glancing at on the way past.
        Tile {
            id: system

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            readonly property real load: Math.max(0, Math.min(1, Cpu.usage || 0))

            door: true
            title: "System"
            caption: `${Fmt.percent(Cpu.usage)} cpu, ${Fmt.percent(Memory.usage)} memory`

            Accessible.name: "System"

            onClicked: root.notch.panel = "resources"

            disc: Rectangle {
                anchors.fill: parent

                radius: width / 2
                color: Theme.surface

                Shape {
                    id: ring

                    anchors.centerIn: parent

                    readonly property int size: Theme.discSize - Theme.space3

                    width: ring.size
                    height: ring.size

                    preferredRendererType: Shape.CurveRenderer

                    Arc {
                        size: ring.size
                        thickness: Theme.ringThickness
                        start: -90
                        strokeColor: Theme.surfacePress
                    }

                    Arc {
                        size: ring.size
                        thickness: Theme.ringThickness
                        start: -90
                        sweep: 360 * system.load
                        strokeColor: system.load >= 0.9 ? Theme.urgent : Theme.accent

                        Behavior on sweep {
                            NumberAnimation {
                                duration: Theme.expandDuration
                                easing.type: Theme.expandEasing
                            }
                        }
                    }
                }
            }
        }
    }

    // ── the session ───────────────────────────────────────────────────────
    // The four ways out, at the foot of the page: a disc each with its name
    // under it, so none has to be recognised from its glyph alone.
    //
    // The two that end the session are pressed twice. The first press turns
    // the disc red and swaps the name for the question, and a second press
    // within a few seconds is the answer; pressing anything else, or
    // waiting, lets it go. The notch folds before any of them runs.

    // which of the two is waiting for its second press, if either
    property string pending: ""

    Timer {
        id: pendingTimer

        interval: Theme.confirmHold

        onTriggered: root.pending = ""
    }

    function press(action: string): void {
        const wasPending = root.pending === action;
        root.pending = "";
        pendingTimer.stop();

        switch (action) {
        case "lock":
            root.notch.expanded = false;
            Power.lock();
            return;
        case "suspend":
            root.notch.expanded = false;
            Power.suspend();
            return;
        }

        if (!wasPending) {
            root.pending = action;
            pendingTimer.restart();
            return;
        }

        root.notch.expanded = false;
        if (action === "reboot")
            Power.reboot();
        else
            Power.poweroff();
    }

    RowLayout {
        Layout.fillWidth: true
        // the marks' hover grounds reach out to the page's edges
        Layout.leftMargin: -Theme.rowPadding
        Layout.rightMargin: -Theme.rowPadding

        spacing: 0

        Repeater {
            model: [
                {
                    action: "lock",
                    icon: Icons.lock,
                    label: "Lock"
                },
                {
                    action: "suspend",
                    icon: Icons.sleep,
                    label: "Sleep"
                },
                {
                    action: "reboot",
                    icon: Icons.restart,
                    label: "Restart"
                },
                {
                    action: "poweroff",
                    icon: Icons.power,
                    label: "Shut down"
                }
            ]

            ListRow {
                id: mark

                required property var modelData

                readonly property bool asking: root.pending === mark.modelData.action

                // an equal quarter each, taken from the page rather than
                // from the width of the word under the disc
                Layout.fillWidth: true
                Layout.preferredWidth: 1

                Accessible.name: mark.modelData.label

                onClicked: root.press(mark.modelData.action)

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    spacing: Theme.space1

                    IconDisc {
                        Layout.alignment: Qt.AlignHCenter

                        icon: mark.modelData.icon
                        size: Theme.discSizeLarge
                        // red for a mark waiting on its second press
                        danger: mark.asking
                    }

                    Caption {
                        Layout.fillWidth: true

                        text: mark.asking ? "Press again" : mark.modelData.label
                        color: {
                            if (mark.asking)
                                return Theme.urgent;
                            return mark.hovered ? Theme.textMuted : Theme.textDim;
                        }

                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
