import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.theme
import qs.util
import qs.widgets

// One result in Spotlight: the thing's own icon, its name, and what it is.
//
// The row Return would open is filled in the accent with its words in the
// ground, the way a selection is; the pointer only washes the row it is on.
// The top hit is the same row drawn larger — a bigger icon, the name at the
// size of a title and what it is under it — because it is the one most
// likely to be the answer; the others are their names alone, so the eye
// runs down a column of names rather than a column of descriptions.
Rectangle {
    id: root

    required property var item
    property bool hit: false
    property bool selected: false

    readonly property bool hovered: mouse.containsMouse
    readonly property int iconSize: root.hit ? Theme.spotlightHitIconSize : Theme.spotlightIconSize

    signal clicked

    implicitHeight: layout.implicitHeight + Theme.rowPadding * 2

    radius: Theme.radiusSmall
    color: {
        if (root.selected)
            return Theme.selection;
        if (mouse.pressed)
            return Theme.rowPress;
        if (root.hovered)
            return Theme.rowHover;
        return Theme.clear(Theme.rowHover);
    }

    Accessible.role: Accessible.Button
    // what the row is read out as, when its name alone would not say it:
    // an answer, or a window among others with the same title
    Accessible.name: root.item.label ?? root.item.title
    Accessible.onPressAction: root.clicked()

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: Nav.pointer()
        onClicked: root.clicked()
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Theme.rowPadding

        spacing: Theme.rowSpacing

        // the application's own icon at its own shape, or a glyph on a disc
        // for anything that has none
        Item {
            Layout.alignment: Qt.AlignVCenter

            implicitWidth: root.iconSize
            implicitHeight: root.iconSize

            IconImage {
                anchors.fill: parent

                visible: (root.item.image ?? "") !== ""

                source: root.item.image ?? ""
                implicitSize: root.iconSize
                asynchronous: true
            }

            IconDisc {
                anchors.fill: parent

                visible: (root.item.image ?? "") === ""

                icon: root.item.icon
                size: root.iconSize
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            spacing: Theme.lineGap

            Sans {
                Layout.fillWidth: true

                text: root.item.title
                color: root.selected ? Theme.onSelection : Theme.text

                font.pixelSize: root.hit ? Theme.fontTitle : Theme.fontBody
                font.weight: root.hit ? Font.DemiBold : Font.Normal
            }

            Caption {
                Layout.fillWidth: true

                visible: root.hit && text !== ""

                text: root.item.caption ?? ""
                color: root.selected ? Theme.onSelectionMuted : Theme.textDim
            }
        }

        // on the row Return would open, the key that does it
        Glyph {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: implicitWidth

            visible: root.selected

            text: Icons.enter
            color: Theme.onSelectionMuted

            font.pixelSize: Theme.fontSmall
        }
    }
}
