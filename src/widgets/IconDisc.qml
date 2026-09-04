import QtQuick
import qs.theme

// A glyph in a disc: the mark at the head of a tile or a row.
//
// The disc is the state. Lit in the accent it says the thing behind it is
// on — a device connected, a link carrying an address — and in the plain
// wash it says the thing is there but idle. The glyph inside only says what
// the thing is, so a row of discs reads as a row of switches before it reads
// as a row of icons.
Rectangle {
    id: root

    property string icon: ""
    property bool on: false
    property int size: Theme.discSize
    // ink for the glyph while the disc is not lit
    property color iconColor: Theme.textBody

    implicitWidth: root.size
    implicitHeight: root.size

    radius: root.size / 2
    color: root.on ? Theme.accent : Theme.surfaceRaised

    Behavior on color {
        ColorFade {}
    }

    Text {
        anchors.centerIn: parent

        text: root.icon
        color: root.on ? Theme.onAccent : root.iconColor

        font.family: Theme.monoFamily
        font.pixelSize: Math.round(root.size * 0.46)

        Behavior on color {
            ColorFade {}
        }
    }
}
