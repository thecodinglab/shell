pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
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

    spacing: Theme.stackSpacing

    // The field borrows the keyboard while the panel is up; hand it back on
    // the way out so escape still steps out of the notch.
    Component.onDestruction: root.notch.takeKeys()

    PanelHeader {
        id: header

        Layout.fillWidth: true

        notch: root.notch
        title: "Bluetooth"

        // in the ink, with the spinner: scanning is busy, not on
        RowLayout {
            visible: Bt.discovering

            spacing: Theme.space2

            Spinner {
                Layout.alignment: Qt.AlignVCenter
            }

            Caption {
                Layout.alignment: Qt.AlignVCenter

                text: "Scanning"
                color: Theme.bezel.textMuted
            }
        }

        // with no adapter there is nothing for a switch to turn on, so
        // there is no switch
        Toggle {
            visible: Bt.available

            checked: Bt.enabled
            label: "Bluetooth"

            onToggled: Bt.toggle()
        }
    }

    SearchField {
        id: search

        Layout.fillWidth: true
        Layout.topMargin: Theme.space1

        visible: Bt.enabled

        placeholder: "Search devices"

        // escape on an empty field is a step back out, the same as it is
        // anywhere else in the notch
        onCancelled: root.notch.dismiss()

        Component.onCompleted: search.take()
    }

    // no spinner of its own while it is looking: the one in the header is
    // already turning
    // the room under the header, with what there is to say in the middle
    // of it: as much as it takes to say it, and any more the page has
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: empty.implicitHeight

        visible: root.matches.length === 0

        Empty {
            id: empty

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            centred: true

            text: {
                if (!Bt.available)
                    return "No Bluetooth adapter";
                if (!Bt.enabled)
                    return "Bluetooth is off";
                if (Bt.devices.length === 0)
                    return Bt.discovering ? "Looking for devices" : "No devices yet";
                return `Nothing called “${search.text.trim()}”`;
            }
        }
    }

    ScrollList {
        Layout.fillWidth: true
        // the rows reach out past the page margin so their hover ground
        // wraps the disc rather than starting at it
        Layout.leftMargin: -Theme.rowPadding
        Layout.rightMargin: -Theme.rowPadding

        visible: root.matches.length > 0

        // the rest of the room under the field, scrolling once it runs out;
        // and any room left over, should rows go while the page is open
        Layout.fillHeight: true
        maxHeight: Math.max(Theme.listMinHeight, root.notch.pageRoom - header.height - search.height - root.spacing * 2)

        values: root.matches

        delegate: ListRow {
            id: deviceRow

            required property var modelData
            required property int index

            readonly property bool busy: Bt.busy(deviceRow.modelData)
            readonly property bool connected: deviceRow.modelData.connected

            width: ListView.view.width

            rule: deviceRow.index < root.matches.length - 1
            ruleInset: Theme.discSizeSmall + Theme.rowSpacing
            // a device mid-handshake has nothing to offer a tap: the next
            // one could only countermand the last
            interactive: !deviceRow.busy

            Accessible.name: Bt.label(deviceRow.modelData)

            onClicked: Bt.activate(deviceRow.modelData)

            IconDisc {
                Layout.alignment: Qt.AlignVCenter

                icon: Icons.device(deviceRow.modelData.icon)
                on: deviceRow.connected
                size: Theme.discSizeSmall
                // a device it already knows a tier louder than a stranger;
                // never the dim tier, which does not read on a disc
                iconColor: deviceRow.modelData.paired ? Theme.bezel.text : Theme.bezel.textMuted
            }

            Label {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                title: Bt.label(deviceRow.modelData)
                caption: Bt.status(deviceRow.modelData)
                // connected is on, and says so in the accent; a handshake
                // is only busy
                captionColor: {
                    if (deviceRow.connected)
                        return Theme.bezel.accentInk;
                    return deviceRow.busy ? Theme.bezel.textMuted : Theme.bezel.textDim;
                }
            }

            Spinner {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: Theme.space1

                visible: deviceRow.busy
            }
        }
    }
}
