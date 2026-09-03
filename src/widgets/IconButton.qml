import QtQuick
import qs.theme

// A glyph you can press.
//
// `filled` is the one primary action in a group — the play button in the
// media card — which gets a solid disc of ink behind it. Everything else is
// the mark alone, lit by a ground that only appears under the pointer, so a
// row of controls is a row of marks until you reach for one of them.
Item {
    id: root

    property string icon: ""
    property bool filled: false
    property bool active: true
    property int size: Theme.actionWidth
    property int pixelSize: Theme.fontBody

    signal clicked

    implicitWidth: root.size
    implicitHeight: root.size

    opacity: root.active ? 1 : 0.3

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.fadeDuration
        }
    }

    Rectangle {
        anchors.fill: parent

        radius: width / 2

        color: {
            if (root.filled)
                return mouse.containsMouse && root.active ? Theme.text : Theme.fill;
            if (!root.active)
                return "transparent";
            if (mouse.pressed)
                return Theme.surfacePress;
            if (mouse.containsMouse)
                return Theme.surfaceHover;
            return "transparent";
        }

        Behavior on color {
            ColorAnimation {
                duration: Theme.fadeDuration
            }
        }
    }

    Text {
        id: label

        anchors.centerIn: parent

        text: root.icon
        color: {
            if (root.filled)
                return Theme.onFill;
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
