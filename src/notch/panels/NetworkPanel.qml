pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.widgets

// Every way out of the machine, and the address it is reachable at on each.
//
// One row per interface `ip` reports as up — ethernet, wifi and tunnels each
// with their own mark — so a machine on a wire and a vpn at once shows both
// addresses. A link with a carrier but no address says so; a machine on
// nothing says offline. There is nothing here to press: the panel is a
// reading, not a control.
ColumnLayout {
    id: root

    required property var notch

    spacing: Theme.expandedSpacing

    PanelHeader {
        Layout.fillWidth: true

        notch: root.notch
        title: "Network"
    }

    Empty {
        visible: Network.interfaces.length === 0

        text: "Not connected to anything."
    }

    Card {
        Layout.fillWidth: true

        visible: Network.interfaces.length > 0

        ColumnLayout {
            spacing: Theme.px(10)

            Repeater {
                model: Network.interfaces

                RowLayout {
                    id: link

                    required property var modelData

                    readonly property bool up: link.modelData.state === "connected"

                    Layout.fillWidth: true

                    spacing: Theme.rowSpacing

                    IconDisc {
                        Layout.alignment: Qt.AlignVCenter

                        icon: Icons.link(link.modelData.kind)
                        on: link.up
                        size: Theme.discSizeSmall
                    }

                    Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        title: link.modelData.name
                        caption: Network.kindLabel(link.modelData.kind)
                    }

                    Num {
                        Layout.alignment: Qt.AlignVCenter

                        text: link.up ? link.modelData.address : "No address"
                        color: link.up ? Theme.textMuted : Theme.urgent

                        font.pixelSize: Theme.fontBody
                    }
                }
            }
        }
    }
}
