import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.util

// A word you can press, on a capsule of the raised ground.
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
    property Scheme scheme: Theme.schemeOf(root)

    signal clicked

    implicitHeight: Theme.buttonHeight
    implicitWidth: row.implicitWidth + Theme.buttonPadding * 2

    radius: height / 2

    color: {
        if (root.primary)
            return !root.enabled ? root.scheme.surface : mouse.containsMouse ? root.scheme.accentHover : root.scheme.accent;
        if (mouse.pressed)
            return root.scheme.surfacePress;
        if (mouse.containsMouse)
            return root.scheme.surfaceHover;
        return root.scheme.surface;
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

            scheme: root.scheme
            text: root.icon
            color: label.color

            Layout.preferredWidth: implicitWidth
            font.pixelSize: Theme.fontBody
        }

        Sans {
            id: label

            Layout.alignment: Qt.AlignVCenter

            scheme: root.scheme
            text: root.text
            color: {
                if (!root.enabled)
                    return root.scheme.textFaint;
                return root.primary ? root.scheme.inkOnAccent : root.scheme.text;
            }

            // the size a mac sets the word on a control in
            font.pixelSize: Theme.fontBody
            font.weight: Font.Medium
        }
    }

    // the accent would be lost on a button filled with it, so on the default
    // button the ring stands just clear of its edge instead
    FocusRing {
        scheme: root.scheme
        inset: root.primary ? -Theme.focusWidth * 2 : 0
        radius: root.radius - inset
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        // the arrow, as over any control; the pointing hand is for links
        cursorShape: Qt.ArrowCursor

        onPressed: Nav.pointer()
        onClicked: root.clicked()
    }
}
