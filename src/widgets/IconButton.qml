import QtQuick
import qs.theme
import qs.util

// A glyph you can press.
//
// `label` is what it does, in words: it is read out, and it is put up as a
// tooltip once the pointer has rested on the mark, so no glyph on the surface
// ever stands for itself alone.
//
// `filled` is the one primary action in a group — the play button — which
// gets a solid disc of ink behind it. Everything else is the mark alone, lit
// by a ground that only appears under the pointer, so a row of controls is a
// row of marks until you reach for one of them.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool filled: false
    property int size: Theme.actionSize
    property int pixelSize: Theme.fontBody

    signal clicked

    readonly property bool hovered: mouse.containsMouse

    implicitWidth: root.size
    implicitHeight: root.size

    activeFocusOnTab: root.enabled

    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.onPressAction: root.clicked()

    Keys.onPressed: event => {
        Nav.key();
        if (event.key !== Qt.Key_Space && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
            return;

        root.clicked();
        event.accepted = true;
    }

    Component.onDestruction: Tip.hide(root)

    Rectangle {
        anchors.fill: parent

        radius: width / 2

        color: {
            if (root.filled)
                return !root.enabled ? Theme.surface : mouse.containsMouse ? Theme.textMuted : Theme.fill;
            if (!root.enabled)
                return "transparent";
            if (mouse.pressed)
                return Theme.surfacePress;
            if (mouse.containsMouse)
                return Theme.surfaceHover;
            return "transparent";
        }
    }

    Text {
        anchors.centerIn: parent

        text: root.icon
        color: {
            if (!root.enabled)
                return Theme.textFaint;
            if (root.filled)
                return Theme.onFill;
            return mouse.containsMouse ? Theme.text : Theme.textMuted;
        }

        font.family: Theme.monoFamily
        font.pixelSize: root.filled ? Theme.fontSmall : root.pixelSize
    }

    FocusRing {
        radius: width / 2
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: Nav.pointer()
        onClicked: root.clicked()

        onContainsMouseChanged: {
            if (mouse.containsMouse && root.label !== "")
                tip.restart();
            else {
                tip.stop();
                Tip.hide(root);
            }
        }
    }

    // the tooltip waits for the pointer to rest, so crossing a row of marks
    // does not flicker through their names
    Timer {
        id: tip

        interval: Theme.tooltipDelay

        onTriggered: Tip.show(root, root.label)
    }
}
