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
// finished thinking.
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

    spacing: Theme.px(10)

    // The field borrows the keyboard while the panel is up; hand it back on
    // the way out so escape still steps out of the notch.
    Component.onDestruction: root.notch.takeKeys()

    PanelHeader {
        id: header

        Layout.fillWidth: true
        Layout.leftMargin: Theme.px(4)

        title: "Bluetooth"

        onBack: root.notch.panel = "home"

        Caption {
            visible: Bt.discovering

            text: "scanning"
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
        padding: Theme.px(9)

        // escape on an empty field is a step back out, the same as it is
        // anywhere else in the notch
        onCancelled: root.notch.dismiss()

        Component.onCompleted: search.take()
    }

    Mono {
        Layout.fillWidth: true
        Layout.margins: Theme.px(4)

        visible: root.matches.length === 0

        text: {
            if (!Bt.available)
                return "no bluetooth adapter";
            if (!Bt.enabled)
                return "adapter is off";
            if (Bt.devices.length === 0)
                return Bt.discovering ? "looking for devices" : "no devices yet";
            return `nothing called “${search.text.trim()}”`;
        }
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

                width: ListView.view.width

                active: deviceRow.modelData.connected
                // a device mid-handshake has nothing to offer a tap: the next
                // one could only countermand the last
                interactive: !deviceRow.busy
                padding: Theme.px(9)

                onClicked: Bt.activate(deviceRow.modelData)

                Glyph {
                    text: Icons.device(deviceRow.modelData.icon)
                    color: deviceRow.active ? Theme.accent : Theme.textMuted
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: Theme.px(1)

                    Sans {
                        Layout.fillWidth: true

                        text: Bt.label(deviceRow.modelData)
                        color: Theme.text

                        font.weight: Font.Medium
                    }

                    Mono {
                        Layout.fillWidth: true

                        text: {
                            const device = deviceRow.modelData;
                            const parts = [];

                            if (device.icon)
                                parts.push(device.icon.replace(/^(audio|input|video)-/, ""));
                            if (device.batteryAvailable)
                                parts.push(`battery ${Fmt.percent(device.battery)}`);
                            else if (!device.paired)
                                parts.push("not paired");

                            return parts.join(" · ");
                        }
                    }
                }

                Spinner {
                    Layout.alignment: Qt.AlignVCenter

                    visible: deviceRow.busy
                }

                Tag {
                    accented: deviceRow.modelData.connected || deviceRow.busy

                    text: Bt.status(deviceRow.modelData)
                }
            }
        }

        ScrollBar {
            id: bar

            flickable: list
        }
    }
}
