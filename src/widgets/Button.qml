import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.util

// A word you can press, on a pill of the raised ground.
//
// `primary` is the default one, the one Return presses, and is filled with
// the accent instead, the way a mac fills the default button of a dialog:
// which button Return will press is state, which is what the accent is
// spent on. Disabled, it keeps its shape and loses its ink.
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
            return !root.enabled ? Theme.surface : mouse.containsMouse ? Theme.accentHover : Theme.accent;
        if (mouse.pressed)
            return Theme.surfacePress;
        if (mouse.containsMouse)
            return Theme.surfaceHover;
        return Theme.surface;
    }

    Behavior on color {
        ColorFade {}
    }

    // held down it sinks a little, and let go of quickly it comes back up
    // from wherever it had got to rather than from the bottom
    scale: press.value

    Spring {
        id: press

        visible: root.visible
        to: mouse.pressed ? Theme.pressScale : 1
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
                return root.primary ? Theme.onAccent : Theme.text;
            }

            font.pixelSize: Theme.fontSmall
            font.weight: Font.Medium
        }
    }

    // the accent would be lost on a button filled with it, so on the default
    // button the ring stands just clear of its edge instead
    FocusRing {
        inset: root.primary ? -Theme.focusWidth * 2 : 0
        radius: root.radius - inset
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
