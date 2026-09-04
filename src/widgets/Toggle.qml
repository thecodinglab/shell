import QtQuick
import qs.theme

// The switch in a panel header.
Rectangle {
    id: root

    property bool checked: false

    signal toggled

    implicitWidth: Theme.px(32)
    implicitHeight: Theme.px(18)

    radius: height / 2
    color: root.checked ? Theme.accent : Theme.track

    Behavior on color {
        ColorFade {}
    }

    Rectangle {
        // the knob rides the full travel, inset by the same 2px at both ends
        x: root.checked ? root.width - width - Theme.px(2) : Theme.px(2)
        anchors.verticalCenter: parent.verticalCenter

        width: root.height - Theme.px(4)
        height: width

        radius: height / 2
        // against the accent the knob has to read as a hole, not a dot
        color: root.checked ? Theme.slab : Theme.textMuted

        Behavior on x {
            Ease {}
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: root.toggled()
    }
}
