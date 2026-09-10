import QtQuick
import QtQuick.Layouts
import qs.theme

// The first row of a page: the way back, what you are looking at, and
// whatever that page wants on the right.
//
// The back button sits in the page margin rather than in the content, so the
// title starts on the same left edge everything under it starts on.
RowLayout {
    id: root

    default property alias trailing: trailingRow.data

    required property var notch
    property string title: ""

    spacing: Theme.space2

    IconButton {
        Layout.alignment: Qt.AlignVCenter
        // reach out into the page margin, so the title stays on the grid
        Layout.leftMargin: -(Theme.actionSize - Theme.iconWidth) / 2

        icon: Icons.back
        label: "Back"

        onClicked: root.notch.panel = "home"
    }

    Title {
        Layout.fillWidth: true

        text: root.title
    }

    RowLayout {
        id: trailingRow

        Layout.alignment: Qt.AlignVCenter

        spacing: Theme.rowSpacing
    }
}
