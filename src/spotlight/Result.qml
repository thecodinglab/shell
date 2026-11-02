import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.theme
import qs.util
import qs.widgets

// One result in Spotlight: the thing's own icon, its name, and what it is.
//
// The row Return would open is filled in the accent, and everything on it —
// the name, the line under it, the window's place and the return mark — is
// drawn in the one ink that reads on the accent, the way a selection is; the
// pointer only washes the row it is on. The top hit is the same row drawn
// larger — a bigger icon, the name at the size of a title and what it is
// under it — because it is the one most likely to be the answer, and an
// answer to a sum is set larger still, in figures that line up. The others
// are their names alone, so the eye runs down a column of names rather than
// a column of descriptions; a window keeps where it is at the far end, since
// two windows of one application are often told apart by nothing else.
//
// Its corners are the sheet's, less the inset it sits at, so a row and the
// sheet round it curve together.
Rectangle {
    id: root

    required property var item
    property bool hit: false
    property bool selected: false
    // what the row is called; the item's own name unless the list has
    // something to say on it for now, a press that wants another
    property string title: root.item.title
    // the row is waiting on a second press that cannot be undone, and is
    // drawn in the red the way a session mark asking the same is
    property bool danger: false

    readonly property bool hovered: mouse.containsMouse
    readonly property int iconSize: root.hit ? Theme.spotlightHitIconSize : Theme.spotlightIconSize
    // the ink for everything on the row but its icon
    readonly property color ink: root.selected ? Theme.pane.inkOnSelection : root.danger ? Theme.pane.urgent : Theme.pane.text

    signal clicked

    implicitHeight: layout.implicitHeight + Theme.rowPadding * 2

    radius: Theme.spotlightRowRadius
    color: {
        if (root.selected)
            return Theme.pane.selection;
        if (mouse.pressed)
            return Theme.pane.rowPress;
        if (root.hovered)
            return Theme.pane.rowHover;
        return Theme.clear(Theme.pane.rowHover);
    }

    // The keys stay in the field, so a row is never focused: it is an item
    // in a list, and the field says which one is selected.
    Accessible.role: Accessible.ListItem
    // what the row is read out as, when its name alone would not say it:
    // an answer, or a window among others with the same title
    Accessible.name: root.title === root.item.title ? (root.item.label ?? root.title) : root.title
    Accessible.selected: root.selected
    Accessible.onPressAction: root.clicked()

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        // the arrow, as over any control; the pointing hand is for links
        cursorShape: Qt.ArrowCursor

        onPressed: Nav.pointer()
        onClicked: root.clicked()
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Theme.rowPadding

        spacing: Theme.rowSpacing

        // the thing's own icon at its own shape, or a glyph on a disc for
        // anything that has none
        Item {
            Layout.alignment: Qt.AlignVCenter

            implicitWidth: root.iconSize
            implicitHeight: root.iconSize

            IconImage {
                anchors.fill: parent

                visible: (root.item.image ?? "") !== "" && !root.danger

                source: root.item.image ?? ""
                implicitSize: root.iconSize
                asynchronous: true
            }

            IconDisc {
                anchors.fill: parent

                visible: (root.item.image ?? "") === "" || root.danger

                icon: root.item.icon
                danger: root.danger
                size: root.iconSize
                // Solid, standing in for an icon of its own: a wash would
                // turn to a pale blot on the selected row.
                color: root.danger ? Theme.pane.urgentSurface : Paint.over(Theme.pane.surface, Theme.pane.ground)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            spacing: Theme.lineGap

            Sans {
                Layout.fillWidth: true

                // Plain, never markup: a title can be anything a window or
                // the clipboard was given, and `<b>` copied is `<b>` shown.
                text: root.title
                textFormat: Text.PlainText
                color: root.ink

                font.family: root.item.answer ? Theme.displayFamily : Theme.sansFamily
                font.pixelSize: root.item.answer ? Theme.fontDisplay : root.hit ? Theme.fontTitle : Theme.fontBody
                font.weight: root.hit ? Font.DemiBold : Font.Normal
                font.features: root.item.answer ? Theme.tabular : ({})
            }

            Caption {
                Layout.fillWidth: true

                visible: root.hit && text !== ""

                text: root.item.caption ?? ""
                textFormat: Text.PlainText
                color: root.selected ? root.ink : Theme.pane.textDim
            }
        }

        // where a window is, at the far end of its row
        Caption {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: layout.width / 2

            visible: !root.hit && (root.item.address ?? "") !== ""

            text: root.item.caption ?? ""
            textFormat: Text.PlainText
            color: root.selected ? root.ink : Theme.pane.textDim
        }

        // on the row Return would open, the key that does it
        Glyph {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: implicitWidth

            visible: root.selected

            text: Icons.enter
            color: root.ink

            font.pixelSize: Theme.fontSmall
        }
    }
}
