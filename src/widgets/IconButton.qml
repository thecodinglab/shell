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
    // anything more a screen reader should say about it than what it does
    property string description: ""
    property bool filled: false
    property int size: Theme.actionSize
    property int pixelSize: Theme.fontBody
    property Scheme scheme: Theme.schemeOf(root)

    signal clicked

    readonly property bool hovered: mouse.containsMouse

    implicitWidth: root.size
    implicitHeight: root.size

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
    Accessible.name: root.label
    Accessible.description: root.description
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
                return !root.enabled ? root.scheme.surface : mouse.containsMouse ? root.scheme.textMuted : root.scheme.fill;
            if (!root.enabled)
                return Theme.clear(root.scheme.surfaceHover);
            if (mouse.pressed)
                return root.scheme.surfacePress;
            if (mouse.containsMouse)
                return root.scheme.surfaceHover;
            return Theme.clear(root.scheme.surfaceHover);
        }

        Behavior on color {
            ColorFade {}
        }
    }

    Text {
        anchors.centerIn: parent

        text: root.icon
        color: {
            if (!root.enabled)
                return root.scheme.textFaint;
            if (root.filled)
                return root.scheme.inkOnFill;
            return mouse.containsMouse ? root.scheme.text : root.scheme.textMuted;
        }

        Behavior on color {
            ColorFade {}
        }

        font.family: Theme.monoFamily
        // the filled one is the primary action in its group, and its mark is
        // set large enough to be the first thing found in it
        font.pixelSize: root.filled ? Theme.fontTitle : root.pixelSize
    }

    FocusRing {
        scheme: root.scheme
        radius: width / 2
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
