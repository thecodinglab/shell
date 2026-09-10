import QtQuick
import QtQuick.Layouts
import qs.theme

// A tile on the home page: a disc, what it is, and one line on how that is
// doing right now. The whole tile is the button.
//
// What sits at its right end says what pressing it does: a chevron for a
// tile that is a door to a panel, or whatever the tile puts in `trailing` —
// a switch, for one that is a setting. `disc` is what the tile can put in
// place of its icon: a ring, for the system tile.
ListRow {
    id: root

    property alias disc: discSlot.data
    property alias trailing: trailingSlot.data

    property string icon: ""
    property bool on: false
    property bool door: false
    property alias title: label.title
    property alias caption: label.caption
    property alias captionColor: label.captionColor

    Item {
        id: discSlot

        Layout.alignment: Qt.AlignVCenter

        implicitWidth: Theme.discSize
        implicitHeight: Theme.discSize

        IconDisc {
            anchors.fill: parent

            visible: root.icon !== ""

            icon: root.icon
            on: root.on
        }
    }

    Label {
        id: label

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
    }

    Glyph {
        Layout.alignment: Qt.AlignVCenter

        visible: root.door

        text: Icons.forward
        color: root.hovered ? Theme.textMuted : Theme.textFaint

        Layout.preferredWidth: implicitWidth
        font.pixelSize: Theme.fontSmall
    }

    Item {
        id: trailingSlot

        Layout.alignment: Qt.AlignVCenter

        visible: children.length > 0

        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
