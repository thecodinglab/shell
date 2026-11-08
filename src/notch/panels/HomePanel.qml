pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Services.Mpris
import qs.theme
import qs.services
import qs.util
import qs.widgets
import qs.notch

// What the notch shows when it first unfolds: what is going on right now,
// and the few things worth reaching for on the way past.
//
// It says what is out of the ordinary rather than reading out everything
// that is fine. With nothing wrong it is short: the head, what is playing,
// how loud and through what, and a row of four marks. What would otherwise
// be a reading nobody acts on — an address that never changes, a processor
// at one percent — stays on its own page, and comes out here only when it
// is something to act on: no address, a processor pinned.
//
// The ways out of the session are rare, and sit behind the power mark in
// the head, which brings out the power pane — see PowerDialog — rather than
// across the foot of the page. The outputs sit behind the name of the one
// in use at the end of the volume bar, which opens into the list of them in
// place, the way a pop-up opens into its list; escape folds it back up
// before it folds the notch.
//
// It is the bezel unfolded, dark whatever the palette, so what it colours
// itself it colours from `Theme.bezel`.
ColumnLayout {
    id: root

    required property var notch

    readonly property var link: Network.primary

    spacing: Theme.sectionSpacing

    // ── what is open in place, and what it resets to ──────────────────────

    // the list of outputs is open under the volume bar
    property bool listing: false
    // the player picked to lead, over the one playing; forgotten on folding
    property MprisPlayer pick: null

    readonly property MprisPlayer lead: Media.players.includes(root.pick) ? root.pick : (Media.players[0] ?? null)
    readonly property var others: Media.players.filter(p => p !== root.lead)

    // Opens the list, or folds it back up the way `back` does.
    function toggleOutputs(): void {
        if (!root.back())
            root.listing = true;
    }

    // One step back, before the notch's own: an open list of outputs folds
    // and hands the keyboard back to the name it opened from. Says whether
    // there was anything to step back from.
    function back(): bool {
        if (!root.listing)
            return false;

        // the keyboard is moved before the rows holding it go, so it never
        // lands nowhere and leaves escape with nothing to hear it
        if (Nav.keyboard)
            outputPicker.forceActiveFocus();
        else
            root.notch.takeKeys();
        root.listing = false;
        return true;
    }

    // Escape from anything on the page lands here on its way up, and goes
    // through the notch, which asks `back` first.
    Keys.onEscapePressed: root.notch.dismiss()

    // Put back as it was once the notch has folded away, not while it is
    // folding, where the page shrinking would be seen.
    Connections {
        target: root.notch

        function onUnfoldedChanged(): void {
            if (root.notch.unfolded)
                return;

            root.listing = false;
            root.pick = null;
        }
    }

    // ── the head ──────────────────────────────────────────────────────────
    // The clock at the size it was on the pill, with the date under it; at
    // the right the dots where they were, the door to the notifications with
    // a count of what is waiting, and the power mark, which brings out the
    // power pane on this monitor.

    RowLayout {
        Layout.fillWidth: true

        spacing: Theme.space2

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            spacing: 0

            Num {
                Layout.fillWidth: true

                text: Time.time
                color: Theme.bezel.text

                // as it was on the pill, so opening the notch does not
                // change what the time looks like
                font.family: Theme.displayFamily
                font.pixelSize: Theme.fontTitle
                font.weight: Font.Medium
            }

            Caption {
                Layout.fillWidth: true

                text: Time.date
                color: Theme.bezel.textMuted
            }
        }

        Dots {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: Theme.space2

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
                // the count on its shoulder is a picture; this is the same
                // figure for whoever cannot see it
                label: Notifs.count ? `Notifications, ${Notifs.count} waiting` : "Notifications"

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

        IconButton {
            Layout.alignment: Qt.AlignVCenter

            icon: Icons.power
            label: "Lock, sleep, restart or shut down"

            onClicked: root.notch.powerRequested()
        }
    }

    // ── what is in use ────────────────────────────────────────────────────
    // the microphone, the camera, the screen, and who has them, while
    // anyone does — see InUse

    InUse {
        Layout.fillWidth: true
    }

    // ── what is playing ───────────────────────────────────────────────────
    // One player in full, the one playing unless another has been picked;
    // every other one a line under it, which picks it, with its own play
    // button so a second thing playing can be stopped without swapping.

    ColumnLayout {
        Layout.fillWidth: true

        visible: root.lead !== null

        spacing: Theme.stackSpacing

        Repeater {
            model: root.lead ? [root.lead] : []

            NowPlaying {
                required property var modelData

                Layout.fillWidth: true

                player: modelData
            }
        }

        Repeater {
            model: root.others

            ListRow {
                id: other

                required property var modelData

                readonly property string app: (other.modelData.identity || other.modelData.desktopEntry) ?? ""

                Layout.fillWidth: true

                bleed: true
                held: toggle.hovered

                Accessible.name: `Show ${other.app}`
                Accessible.description: other.modelData.trackTitle

                // every line is built again once the lead changes, this one
                // among them, so the keyboard goes back to the notch first
                onClicked: {
                    root.notch.takeKeys();
                    root.pick = other.modelData;
                }

                Sans {
                    Layout.alignment: Qt.AlignVCenter

                    text: other.app
                    color: Theme.bezel.textMuted
                }

                Caption {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    text: other.modelData.trackTitle || "Unknown track"
                }

                IconButton {
                    id: toggle

                    Layout.alignment: Qt.AlignVCenter

                    icon: other.modelData.isPlaying ? Icons.pause : Icons.play
                    label: `${other.modelData.isPlaying ? "Pause" : "Play"} ${other.app}`
                    enabled: other.modelData.canTogglePlaying

                    onClicked: other.modelData.togglePlaying()
                }
            }
        }
    }

    // The room the sheet has over, between what is going on and the
    // controls, so the sound and the marks always sit at the foot of the
    // page where the hand expects them, the way a control centre's do. It
    // takes no gap of its own, so a page that does fill the sheet is not
    // pushed past it by one.
    Item {
        Layout.fillHeight: true
        Layout.topMargin: -root.spacing
    }

    // ── sound ─────────────────────────────────────────────────────────────
    // How loud, and through what: the bar, and at its end the name of the
    // output, a pop-up that floats the list of outputs over the page.

    RowLayout {
        Layout.fillWidth: true

        spacing: Theme.space2

        // the bar alone: the figure is in the panel, and with nowhere for
        // the sound to go the bar has nothing to set and stays put
        Volume {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            node: Audio.sink
            figure: false
        }

        ListRow {
            id: outputPicker

            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 0
            // its ground reaches out to the page's edge, so the chevrons
            // line up with everything else down the right
            Layout.rightMargin: -Theme.rowPadding
            Layout.maximumWidth: Math.round(root.width * 0.45)

            selected: root.listing

            Accessible.role: Accessible.ComboBox
            Accessible.name: Audio.sink ? `Output, ${Audio.label(Audio.sink)}` : "No output"
            Accessible.description: "Choose where the sound goes"

            onClicked: root.toggleOutputs()

            Caption {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                text: Audio.sink ? Audio.label(Audio.sink) : "No output"
                color: outputPicker.hovered ? Theme.bezel.text : Theme.bezel.textMuted
            }

            Glyph {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: -Theme.space2
                Layout.preferredWidth: implicitWidth

                text: Icons.choose
                color: outputPicker.hovered ? Theme.bezel.text : Theme.bezel.textMuted

                font.pixelSize: Theme.fontSmall
            }
        }
    }

    // ...and the list it opens, the one in use checked the way a mac checks
    // it in a pop-up menu, with the sound page at its foot. It floats over
    // the page in the notch's overlay rather than being laid out on it, so
    // opening it never moves the page or changes the sheet's height. It
    // hangs under the name, or stands over it when there is no room below,
    // its right edge on the name's. A click anywhere else on the sheet
    // closes it and does nothing more, and the page under it holds still.
    //
    // Made on the overlay as the page is, rather than declared on the page,
    // which would make it one of the page's sections; and so put away by
    // hand with the page.
    property Item outputs: null

    Component.onCompleted: root.outputs = outputsMenu.createObject(root.notch.overlay)
    Component.onDestruction: root.outputs?.destroy()

    Component {
        id: outputsMenu

        Item {
            id: outputs

            anchors.fill: parent

            visible: root.listing

            MouseArea {
                anchors.fill: parent

                acceptedButtons: Qt.AllButtons

                onPressed: root.back()
                onWheel: wheel => wheel.accepted = true
            }

            // where the name is on the sheet, taken as the list opens: the page
            // under it holds still while it is open
            readonly property point at: root.listing ? outputPicker.mapToItem(outputs, 0, 0) : Qt.point(0, 0)
            readonly property real below: outputs.at.y + outputPicker.height + Theme.space1
            // the room it has either side of the name, inside the sheet
            readonly property real roomBelow: outputs.height - Theme.pagePadding - outputs.below
            readonly property real roomAbove: outputs.at.y - Theme.space1 - Theme.pagePadding
            readonly property real natural: list.implicitHeight + Theme.menuInset * 2
            // under the name if it fits there, or if there is more room there
            // than over it
            readonly property bool down: outputs.roomBelow >= outputs.natural || outputs.roomBelow >= outputs.roomAbove

            Shadow {
                target: menu
                radius: menu.radius
            }

            Rectangle {
                id: menu

                // glass, and everything on it drawn for glass
                objectName: Theme.paneTag

                x: Math.round(outputs.at.x + outputPicker.width - menu.width)
                y: Math.round(outputs.down ? outputs.below : outputs.at.y - Theme.space1 - menu.height)

                width: Theme.menuWidth
                // as long as the list, or as the room it has, and it scrolls
                // inside that: it never reaches past the sheet
                height: Math.min(outputs.natural, outputs.down ? outputs.roomBelow : outputs.roomAbove)

                // concentric with the rows' grounds, an inset out
                radius: Theme.radiusSmall + Theme.menuInset
                color: Theme.pane.glass

                Accessible.role: Accessible.PopupMenu
                Accessible.name: "Output"

                // escape from a row lands here, and folds the list
                Keys.onEscapePressed: root.back()

                Flickable {
                    id: scroller

                    anchors.fill: parent
                    anchors.margins: Theme.menuInset

                    clip: true
                    contentHeight: list.implicitHeight
                    interactive: scroller.contentHeight > scroller.height
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: list

                        width: scroller.width

                        spacing: 0

                        Repeater {
                            model: root.listing ? Audio.sinks : []

                            ListRow {
                                id: output

                                required property var modelData

                                readonly property bool current: output.modelData === Audio.sink

                                Layout.fillWidth: true

                                Accessible.name: output.current ? `${Audio.label(output.modelData)}, chosen` : Audio.label(output.modelData)

                                onClicked: {
                                    Audio.setDefaultSink(output.modelData);
                                    root.back();
                                }

                                // the keyboard lands on the one in use
                                Component.onCompleted: {
                                    if (output.current && Nav.keyboard)
                                        output.forceActiveFocus();
                                }

                                // a column of its own, there whether or not the row
                                // is checked, so the names line up
                                Glyph {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: Theme.iconWidth

                                    text: output.current ? Icons.check : ""
                                    color: Theme.pane.text
                                }

                                Sans {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    text: Audio.label(output.modelData)
                                }
                            }
                        }

                        Rule {
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.menuInset
                            Layout.bottomMargin: Theme.menuInset
                        }

                        ListRow {
                            id: soundPage

                            Layout.fillWidth: true

                            Accessible.name: "Sound settings"

                            onClicked: {
                                root.back();
                                root.notch.panel = "audio";
                            }

                            Item {
                                Layout.preferredWidth: Theme.iconWidth
                            }

                            Sans {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                text: "Sound settings"
                            }

                            Glyph {
                                Layout.alignment: Qt.AlignVCenter

                                text: Icons.forward

                                font.pixelSize: Theme.fontSmall
                            }
                        }
                    }
                }
            }

            // the rim of the glass, over it rather than round it
            Rim {
                target: menu
                radius: menu.radius
            }
        }
    }

    // ── four marks ────────────────────────────────────────────────────────
    // Bluetooth, the network, staying awake and the system, a disc each with
    // its name under it. A lit disc means the thing is on: the radio up, a
    // link carrying an address, the inhibitor held. The name gives way to
    // what is wrong when something is, in the red — no address, offline, a
    // processor or memory at nine tenths — and otherwise stays the name, so
    // the row reads the same every time it is opened.
    //
    // Three of them are doors to their pages. Stay awake has no page: the
    // mark is its switch.

    component Mark: ListRow {
        id: mark

        property string icon: ""
        property bool lit: false
        property string name: ""
        // what is wrong, said in place of the name
        property string problem: ""
        property bool checkable: false
        property bool checked: false
        property alias disc: slot.data

        // an equal quarter each, taken from the page rather than from the
        // width of the word under the disc
        Layout.fillWidth: true
        Layout.preferredWidth: 1

        Accessible.role: mark.checkable ? Accessible.CheckBox : Accessible.Button
        Accessible.name: mark.name
        Accessible.checkable: mark.checkable
        Accessible.checked: mark.checked
        Accessible.onToggleAction: mark.clicked()

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            spacing: Theme.space1

            Item {
                id: slot

                Layout.alignment: Qt.AlignHCenter

                implicitWidth: Theme.discSizeLarge
                implicitHeight: Theme.discSizeLarge

                IconDisc {
                    anchors.fill: parent

                    visible: mark.icon !== ""

                    icon: mark.icon
                    on: mark.lit
                    size: Theme.discSizeLarge
                    pressed: mark.pressed
                }
            }

            Caption {
                Layout.fillWidth: true

                text: mark.problem || mark.name
                color: {
                    if (mark.problem)
                        return Theme.bezel.urgent;
                    return mark.hovered ? Theme.bezel.textMuted : Theme.bezel.textDim;
                }
                font.features: Theme.tabular

                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        // the marks' hover grounds reach out to the page's edges
        Layout.leftMargin: -Theme.rowPadding
        Layout.rightMargin: -Theme.rowPadding

        spacing: 0

        Mark {
            icon: {
                if (!Bt.enabled)
                    return Icons.bluetoothOff;
                return Bt.primary ? Icons.device(Bt.primary.icon) : Icons.bluetooth;
            }
            // the radio, not a device on it
            lit: Bt.enabled
            name: "Bluetooth"

            Accessible.description: {
                if (!Bt.available)
                    return "No adapter";
                if (!Bt.enabled)
                    return "Off";
                if (Bt.primary)
                    return [Bt.label(Bt.primary), Bt.battery(Bt.primary)].filter(part => part).join(", ");
                return "On";
            }

            onClicked: root.notch.panel = "bluetooth"
        }

        Mark {
            id: network

            icon: root.link ? Icons.link(root.link.kind) : Icons.networkOff
            lit: Network.state === "connected"
            // named for what it is rather than for the setting: a machine
            // on a wire is on ethernet, not on "network"
            name: root.link ? Network.kindLabel(root.link.kind) : "Network"
            problem: {
                switch (Network.state) {
                case "connected":
                    return "";
                case "linked":
                    return "No address";
                default:
                    return "Offline";
                }
            }

            Accessible.description: Network.state === "connected" ? Network.address : network.problem

            onClicked: root.notch.panel = "network"
        }

        // The inhibitor: on, the notch holds a wayland inhibitor on its
        // window and the idle daemon neither locks the screen nor turns it
        // off; off, the daemon is left to its timeouts.
        Mark {
            icon: Icons.awake
            lit: Power.awake
            name: "Stay awake"
            checkable: true
            checked: Power.awake

            onClicked: Power.awake = !Power.awake
        }

        // The door to the system page. Its disc is a ring rather than a
        // glyph — how busy the processor is, read the way the dials inside
        // are read — and it only says a figure when one is worth acting on.
        Mark {
            id: system

            readonly property real load: Math.max(0, Math.min(1, Cpu.usage || 0))

            name: "System"
            problem: {
                if (system.load >= 0.9)
                    return `CPU ${Fmt.percent(Cpu.usage)}`;
                if ((Memory.usage || 0) >= 0.9)
                    return `Memory ${Fmt.percent(Memory.usage)}`;
                return "";
            }

            Accessible.description: `CPU ${Fmt.percent(Cpu.usage)}, memory ${Fmt.percent(Memory.usage)}`

            onClicked: root.notch.panel = "resources"

            disc: Rectangle {
                anchors.fill: parent

                radius: width / 2
                color: Theme.bezel.surface

                Shape {
                    id: ring

                    anchors.centerIn: parent

                    readonly property int size: Theme.discSizeLarge - Theme.space3

                    width: ring.size
                    height: ring.size

                    preferredRendererType: Shape.CurveRenderer

                    // The empty ring a step up from the disc it sits in. On
                    // the bezel the track is the disc's own ground, and a
                    // ring the colour of what is under it is no ring.
                    Arc {
                        size: ring.size
                        thickness: Theme.ringThickness
                        start: -90
                        strokeColor: Theme.bezel.surfacePress
                    }

                    // in the ink, as the dials inside are: how busy the
                    // processor is is a reading, not something switched on
                    Arc {
                        size: ring.size
                        thickness: Theme.ringThickness
                        start: -90
                        sweep: load.value
                        strokeColor: system.load >= 0.9 ? Theme.bezel.urgent : Theme.bezel.fill
                    }
                }

                // out here rather than on the arc, which is a path and takes
                // nothing but the pieces of one
                Spring {
                    id: load

                    visible: ring.visible
                    to: 360 * system.load
                }
            }
        }
    }
}
