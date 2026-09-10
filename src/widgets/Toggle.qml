import QtQuick
import qs.theme
import qs.util

// A switch. Lit in the accent when it is on, the plain track when it is not;
// the knob rides the full travel between the two.
Rectangle {
    id: root

    property bool checked: false
    // what it switches, in words
    property string label: ""

    signal toggled

    implicitWidth: Theme.switchWidth
    implicitHeight: Theme.switchHeight

    radius: height / 2
    color: {
        if (!root.enabled)
            return Theme.surface;
        return root.checked ? Theme.accent : Theme.track;
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
        x: root.checked ? root.width - width - Theme.switchInset : Theme.switchInset
        anchors.verticalCenter: parent.verticalCenter

        width: root.height - Theme.switchInset * 2
        height: width

        radius: height / 2
        // against the accent the knob has to read as a hole, not a dot
        color: {
            if (!root.enabled)
                return Theme.textFaint;
            return root.checked ? Theme.onAccent : Theme.textMuted;
        }

        Behavior on x {
            Ease {}
        }
    }

    // too small to hold a ring: it goes round the outside
    FocusRing {
        inset: -Theme.space1
        radius: height / 2
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor

        onPressed: Nav.pointer()
        onClicked: root.toggled()
    }
}
