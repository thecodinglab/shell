import QtQuick
import qs.theme

// Figures, labels and anything that has to line up with the row above it.
Text {
    color: Theme.textDim

    font.family: Theme.monoFamily
    font.pixelSize: Theme.fontSmall

    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
