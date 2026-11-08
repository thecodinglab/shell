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

    spacing: Theme.stackSpacing

    PanelHeader {
        Layout.fillWidth: true

        notch: root.notch
        title: "Network"
    }

    Empty {
        visible: Network.interfaces.length === 0

        text: "Offline"
    }

    ColumnLayout {
        Layout.fillWidth: true

        visible: Network.interfaces.length > 0

        spacing: 0

        Repeater {
            model: Network.interfaces

            ListRow {
                id: link

                required property var modelData
                required property int index

                readonly property bool up: link.modelData.state === "connected"

                Layout.fillWidth: true

                bleed: true
                interactive: false
                rule: link.index < Network.interfaces.length - 1
                ruleInset: Theme.discSizeSmall + Theme.rowSpacing

                Accessible.name: `${Network.kindLabel(link.modelData.kind)}, ${link.up ? link.modelData.address : "No address"}`

                IconDisc {
                    Layout.alignment: Qt.AlignVCenter

                    icon: Icons.link(link.modelData.kind)
                    on: link.up
                    size: Theme.discSizeSmall
                }

                // named for what the link is, with the name the kernel gave
                // it underneath for whoever needs to find it in `ip`
                Label {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    title: Network.kindLabel(link.modelData.kind)
                    caption: link.modelData.name
                }

                Num {
                    Layout.alignment: Qt.AlignVCenter

                    text: link.up ? link.modelData.address : "No address"
                    color: link.up ? Theme.bezel.textMuted : Theme.bezel.urgent

                    font.pixelSize: Theme.fontBody
                }
            }
        }
    }

    // the sheet is the same height whatever is on it; what this page does
    // not fill is left at its foot, rather than spread between its sections;
    // and it takes no gap of its own, so a page that does fill the sheet is
    // not pushed past it by one
    Item {
        Layout.fillHeight: true
        Layout.topMargin: -root.spacing
    }
}
