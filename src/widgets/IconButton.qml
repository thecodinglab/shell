import QtQuick
import qs.theme

// A glyph you can press. `filled` is the one primary action in a group — the
// play button in the media card — which gets the accent disc behind it.
Item {
    id: root

    property string icon: ""
    property bool filled: false
    property bool active: true
    property int size: Theme.px(22)
    property int pixelSize: Theme.fontBody

    signal clicked

    implicitWidth: root.filled ? root.size : Math.max(label.implicitWidth, Theme.px(16))
    implicitHeight: root.filled ? root.size : Math.max(label.implicitHeight, Theme.px(16))

    opacity: root.active ? 1 : 0.35

    Rectangle {
        visible: root.filled

        anchors.fill: parent
        radius: width / 2
        color: Theme.accent
    }

    Text {
        id: label

        anchors.centerIn: parent

        text: root.icon
        color: {
            if (root.filled)
                return Theme.onAccent;
            return mouse.containsMouse ? Theme.text : Theme.textBody;
        }

        font.family: Theme.monoFamily
        font.pixelSize: root.filled ? Theme.fontSmall : root.pixelSize
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.active
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }
}
