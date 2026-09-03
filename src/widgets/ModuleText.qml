import QtQuick
import qs.theme

// A single text module inside a group.
Text {
    height: parent?.height ?? implicitHeight
    verticalAlignment: Text.AlignVCenter

    leftPadding: Theme.modulePadding
    rightPadding: Theme.modulePadding

    color: Theme.foreground

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontPixelSize
    font.letterSpacing: Theme.letterSpacing
}
