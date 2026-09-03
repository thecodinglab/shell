pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.util
import qs.widgets

// Everything bluez knows about, in one list.
//
// A row is a single gesture that does the obvious next thing: pair what is
// new, connect what is known, hang up on what is already connected. Whatever
// bluez is still thinking about spins instead, and takes no taps until it has
// finished thinking. The line under a device's name says which of those it
// is; a lit disc beside it says it is on the line right now.
//
// The panel neither starts nor stops discovery — it only reports it, in the
// header. The field at the top narrows the list down rather than going
// looking for anything to put in it.
ColumnLayout {
    id: root

    required property var notch

    readonly property var matches: Bt.enabled ? Bt.search(search.text) : []

    // What is left for the list once the panel has had its half of the
    // screen: everything above the list is a fixed height, so the list gets
    // the rest and scrolls once it runs out.
    readonly property int listMax: Math.max(Theme.listMinHeight, root.notch.bodyMaxHeight - header.height - search.height - root.spacing * 2)

    spacing: Theme.expandedSpacing

    // The field borrows the keyboard while the panel is up; hand it back on
    // the way out so escape still steps out of the notch.
    Component.onDestruction: root.notch.takeKeys()

    PanelHeader {
        id: header

        Layout.fillWidth: true

        title: "Bluetooth"

        onBack: root.notch.panel = "home"

        Caption {
            visible: Bt.discovering

            text: "Scanning"
            color: Theme.accent
        }

        Toggle {
            checked: Bt.enabled

            onToggled: Bt.toggle()
        }
    }

    SearchField {
        id: search

        Layout.fillWidth: true

        visible: Bt.enabled

        placeholder: "Search devices"

        // escape on an empty field is a step back out, the same as it is
        // anywhere else in the notch
        onCancelled: root.notch.dismiss()

        Component.onCompleted: search.take()
    }

    Sans {
        Layout.fillWidth: true
        Layout.margins: Theme.cardPadding

        visible: root.matches.length === 0

        text: {
            if (!Bt.available)
                return "No bluetooth adapter on this machine.";
            if (!Bt.enabled)
                return "Turn bluetooth on to see devices.";
            if (Bt.devices.length === 0)
                return Bt.discovering ? "Looking for devices…" : "No devices yet.";
            return `Nothing called “${search.text.trim()}”.`;
        }
        color: Theme.textDim
    }

    // The list, and the bar that turns up beside it once there is more in it
    // than fits. The two are siblings so the bar holds still while the list
    // scrolls under it.
    Item {
        Layout.fillWidth: true
        // grows with the list until the notch would be half the screen tall
        Layout.preferredHeight: Math.min(list.contentHeight, root.listMax)

        visible: root.matches.length > 0

        ListView {
            id: list

            anchors.fill: parent
            // the gutter the bar needs, taken from the list only when there
            // is going to be a bar in it
            anchors.rightMargin: bar.overflowing ? bar.width : 0

            clip: true
            spacing: Theme.listSpacing
            boundsBehavior: Flickable.StopAtBounds

            model: root.matches

            delegate: ListRow {
                id: deviceRow

                required property var modelData

                readonly property bool busy: Bt.busy(deviceRow.modelData)
                readonly property bool connected: deviceRow.modelData.connected

                width: ListView.view.width

                flat: true
                // a device mid-handshake has nothing to offer a tap: the next
                // one could only countermand the last
                interactive: !deviceRow.busy
                padding: Theme.rowPadding

                onClicked: Bt.activate(deviceRow.modelData)

                IconDisc {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Theme.px(2)

                    icon: Icons.device(deviceRow.modelData.icon)
                    on: deviceRow.connected
                    size: Theme.discSizeSmall
                    iconColor: deviceRow.modelData.paired ? Theme.textBody : Theme.textMuted
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    spacing: Theme.px(1)

                    Sans {
                        Layout.fillWidth: true

                        text: Bt.label(deviceRow.modelData)
                        color: Theme.text

                        font.weight: Font.Medium
                    }

                    Caption {
                        Layout.fillWidth: true

                        // What is happening to it, or failing that what it
                        // is. Every paired row connects when it is clicked,
                        // so that is not worth saying on each of them.
                        text: {
                            const device = deviceRow.modelData;

                            switch (Bt.status(device)) {
                            case "pairing":
                                return "Pairing…";
                            case "connecting":
                                return "Connecting…";
                            case "disconnecting":
                                return "Disconnecting…";
                            case "connected":
                                return device.batteryAvailable ? `Connected · ${Fmt.percent(device.battery)}` : "Connected";
                            case "pair":
                                return "Not paired";
                            default:
                                return Bt.kind(device);
                            }
                        }
                        color: deviceRow.connected || deviceRow.busy ? Theme.accent : Theme.textDim
                    }
                }

                Spinner {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: Theme.px(4)

                    visible: deviceRow.busy
                }
            }
        }

        ScrollBar {
            id: bar

            flickable: list
        }
    }
}
