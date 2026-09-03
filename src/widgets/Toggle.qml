import QtQuick
import qs.theme

// The switch in a panel header.
Rectangle {
    id: root

    property bool checked: false

    signal toggled

    implicitWidth: Theme.px(30)
    implicitHeight: Theme.px(16)

    radius: height / 2
    color: root.checked ? Theme.accent : Theme.track

    Behavior on color {
        ColorAnimation {
            duration: Theme.fadeDuration
        }
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
            NumberAnimation {
                duration: Theme.fadeDuration
                easing.type: Theme.expandEasing
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: root.toggled()
    }
}
