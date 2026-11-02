import QtQuick
import qs.theme
import qs.util

// A switch. Lit in the accent when it is on, the plain track when it is not;
// the knob rides the full travel between the two. Under the pointer it
// takes a step toward the ink either way, so it reads as something to press
// before it is pressed.
Rectangle {
    id: root

    property bool checked: false
    // what it switches, in words
    property string label: ""
    property Scheme scheme: Theme.schemeOf(root)

    signal toggled

    implicitWidth: Theme.switchWidth
    implicitHeight: Theme.switchHeight

    radius: height / 2
    color: {
        if (!root.enabled)
            return root.scheme.surface;
        if (root.checked)
            return mouse.containsMouse ? root.scheme.accentHover : root.scheme.accent;
        return mouse.containsMouse ? root.scheme.surfaceHover : root.scheme.track;
    }

    Behavior on color {
        ColorFade {}
    }

    activeFocusOnTab: root.enabled

    Accessible.role: Accessible.CheckBox
    Accessible.name: root.label
    Accessible.checked: root.checked
    Accessible.onToggleAction: root.toggled()

    Keys.onPressed: event => {
        Nav.key();
        if (event.key !== Qt.Key_Space && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
            return;

        root.toggled();
        event.accepted = true;
    }

    Rectangle {
        x: Math.round(knob.value)
        anchors.verticalCenter: parent.verticalCenter

        width: root.height - Theme.switchInset * 2
        height: width

        radius: height / 2
        // against the accent the knob has to read as a hole, not a dot
        color: {
            if (!root.enabled)
                return root.scheme.textFaint;
            return root.checked ? root.scheme.inkOnAccent : root.scheme.textMuted;
        }

        // flicked back before it has got there, it turns round mid-way
        Spring {
            id: knob

            visible: root.visible
            to: root.checked ? root.width - (root.height - Theme.switchInset * 2) - Theme.switchInset : Theme.switchInset
        }
    }

    // too small to hold a ring: it goes round the outside
    FocusRing {
        scheme: root.scheme
        inset: -Theme.space1
        radius: height / 2
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        // the arrow, as over any control; the pointing hand is for links
        cursorShape: Qt.ArrowCursor

        onPressed: Nav.pointer()
        onClicked: root.toggled()
    }
}
