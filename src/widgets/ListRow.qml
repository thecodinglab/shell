import QtQuick
import QtQuick.Layouts
import qs.theme

// A row in a list, or a tile in the home panel: an icon, something that grows
// to fill the space, and a trailing figure.
//
// `active` is what a connected device or the selected output gets — the
// accent wash and the outline that goes with it.
Rectangle {
    id: root

    default property alias content: layout.data

    property bool active: false
    property bool interactive: true
    property int padding: Theme.rowPadding

    readonly property bool hovered: mouse.containsMouse

    signal clicked

    implicitWidth: layout.implicitWidth + root.padding * 2
    implicitHeight: layout.implicitHeight + root.padding * 2

    radius: Theme.rowRadius

    color: {
        if (root.active)
            return Theme.accentSurface;
        if (root.interactive && mouse.containsMouse)
            return Theme.surfaceHover;
        return Theme.surface;
    }

    border.width: root.active ? 1 : 0
    border.color: Theme.accentBorder

    Behavior on color {
        ColorAnimation {
            duration: Theme.fadeDuration
        }
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
