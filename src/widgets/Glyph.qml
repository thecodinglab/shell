import QtQuick
import qs.theme

// An icon, in a column of fixed width so a list of them lines up no matter
// how wide the individual glyphs are.
Text {
    color: Theme.textBody

    font.family: Theme.monoFamily
    font.pixelSize: Theme.fontBody

    width: Theme.iconWidth
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
