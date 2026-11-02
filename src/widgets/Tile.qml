import QtQuick
import QtQuick.Layouts
import qs.theme

// A tile on the home page: a disc, what it is, and one line on how that is
// doing right now. The whole tile is the button, and stands on a ground of
// its own, a module the way the blocks of a control centre are: a capsule,
// its ends concentric with the disc at its head.
//
// What sits at its right end says what pressing it does: a chevron for a
// tile that is a door to a panel, or whatever the tile puts in `trailing` —
// a switch, say. `disc` is what the tile can put in place of its icon: a
// ring, for the system tile.
//
// A tile that is a setting rather than a door is `checkable`: the whole tile
// is the switch, its lit disc says it is on, and it is announced as
// something checked or not rather than as a button.
ListRow {
    id: root

    raised: true
    padding: Theme.space3
    radius: height / 2

    property alias disc: discSlot.data
    property alias trailing: trailingSlot.data

    property string icon: ""
    property bool on: false
    property bool door: false
    property alias title: label.title
    property alias caption: label.caption
    property alias captionColor: label.captionColor
    property bool checkable: false
    property bool checked: false

    Accessible.role: root.checkable ? Accessible.CheckBox : Accessible.Button
    Accessible.name: root.title
    Accessible.description: root.caption
    Accessible.checkable: root.checkable
    Accessible.checked: root.checked
    Accessible.onToggleAction: root.clicked()

    Item {
        id: discSlot

        Layout.alignment: Qt.AlignVCenter

        implicitWidth: Theme.discSize
        implicitHeight: Theme.discSize

        IconDisc {
            anchors.fill: parent

            visible: root.icon !== ""

            scheme: root.scheme
            icon: root.icon
            on: root.on
            pressed: root.pressed
        }
    }

    Label {
        id: label

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        scheme: root.scheme
    }

    Glyph {
        Layout.alignment: Qt.AlignVCenter
        // A small mark needs less air before it than the row's spacing,
        // which is sized for a disc: it hangs back into the gap, the way
        // the chevron on a section's head does, and leaves the caption that
        // much more of the tile.
        Layout.leftMargin: -Theme.space2

        visible: root.door

        scheme: root.scheme
        text: Icons.forward
        // dim rather than faint: it is the only thing saying the tile opens
        // a page, and has to be read as surely as the caption beside it
        color: root.hovered ? root.scheme.textMuted : root.scheme.textDim

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
