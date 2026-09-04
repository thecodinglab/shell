import QtQuick
import QtQuick.Layouts
import qs.theme

// A row in a list, or a module on the home panel: something you can press,
// laid out left to right.
//
// Two grounds. A module (`flat: false`) sits on the slab on a wash of its
// own, and answers the pointer by stepping a shade lighter, lighter again
// while it is held. A row in a list (`flat: true`) has no ground at all
// until the pointer finds it, so a list is a column of names rather than a
// stack of boxes.
Rectangle {
    id: root

    default property alias content: layout.data

    property bool flat: false
    property bool interactive: true
    property int padding: Theme.rowPadding

    readonly property bool hovered: mouse.containsMouse

    signal clicked

    implicitWidth: layout.implicitWidth + root.padding * 2
    implicitHeight: layout.implicitHeight + root.padding * 2

    radius: root.flat ? Theme.rowRadius : Theme.cardRadius

    color: {
        if (!root.interactive)
            return root.flat ? "transparent" : Theme.surface;
        if (mouse.pressed)
            return root.flat ? Theme.rowPress : Theme.surfacePress;
        if (mouse.containsMouse)
            return root.flat ? Theme.rowHover : Theme.surfaceHover;
        return root.flat ? "transparent" : Theme.surface;
    }

    Behavior on color {
        ColorFade {}
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: root.padding

        spacing: Theme.rowSpacing
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }
}
