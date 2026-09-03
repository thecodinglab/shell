import QtQuick
import qs.theme

// The small tracked-out label above a section or a figure.
Text {
    color: Theme.textDim

    font.family: Theme.monoFamily
    font.pixelSize: Theme.fontSmall
    font.letterSpacing: Theme.fontSmall * 0.12
    font.capitalization: Font.AllUppercase

    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
