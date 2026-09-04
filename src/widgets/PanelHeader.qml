import QtQuick
import QtQuick.Layouts
import qs.theme

// The first row of a sub-panel: the way back, what you are looking at, and
// whatever that panel wants on the right.
//
// Inset to the same margin a module sets its contents in by, so the title
// hangs off the edge the discs and the glyphs below it hang off.
RowLayout {
    id: root

    default property alias trailing: trailingRow.data

    required property var notch
    property string title: ""

    spacing: Theme.px(6)

    IconButton {
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: Theme.px(4)

        icon: Icons.back
        pixelSize: Theme.fontSmall

        onClicked: root.notch.panel = "home"
    }

    Title {
        Layout.fillWidth: true

        text: root.title
    }

    RowLayout {
        id: trailingRow

        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: Theme.px(4)

        spacing: Theme.rowSpacing
    }
}
