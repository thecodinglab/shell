import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.util

// A word you can press, on a pill of the raised ground.
//
// `primary` is the one that matters on its page, and is filled with the ink
// instead. Disabled, it keeps its shape and loses its ink.
Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property bool primary: false

    signal clicked

    implicitHeight: Theme.buttonHeight
    implicitWidth: row.implicitWidth + Theme.buttonPadding * 2

    radius: height / 2

    color: {
        if (root.primary)
            return !root.enabled ? Theme.surface : mouse.containsMouse ? Theme.textMuted : Theme.fill;
        if (mouse.pressed)
            return Theme.surfacePress;
        if (mouse.containsMouse)
            return Theme.surfaceHover;
        return Theme.surface;
    }

    activeFocusOnTab: root.enabled

    Accessible.role: Accessible.Button
    Accessible.name: root.text
    Accessible.onPressAction: root.clicked()

    Keys.onPressed: event => {
        Nav.key();
        if (event.key !== Qt.Key_Space && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
            return;

        root.clicked();
        event.accepted = true;
    }

    RowLayout {
        id: row

        anchors.centerIn: parent

        spacing: Theme.space1

        Glyph {
            Layout.alignment: Qt.AlignVCenter

            visible: root.icon !== ""

            text: root.icon
            color: label.color

            Layout.preferredWidth: implicitWidth
            font.pixelSize: Theme.fontSmall
        }

        Sans {
            id: label

            Layout.alignment: Qt.AlignVCenter

            text: root.text
            color: {
                if (!root.enabled)
                    return Theme.textFaint;
                return root.primary ? Theme.onFill : Theme.text;
            }

            font.pixelSize: Theme.fontSmall
            font.weight: Font.Medium
        }
    }

    FocusRing {
        radius: root.radius
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: Nav.pointer()
        onClicked: root.clicked()
    }
}
