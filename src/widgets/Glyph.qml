import QtQuick
import qs.theme

// An icon, in a column of fixed width so a list of them lines up no matter
// how wide the individual glyphs are. The one place the mono family is
// actually load-bearing: the marks come out of its nerd font patch.
Text {
    color: Theme.textMuted

    font.family: Theme.monoFamily
    font.pixelSize: Theme.fontBody

    width: Theme.iconWidth
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
