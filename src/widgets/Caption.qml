import QtQuick
import qs.theme

// The small tier: the line under a name, a date, an axis. Quiet ink in
// sentence case — a label is there to name the thing beside it, and setting
// it louder than what it names defeats it.
Text {
    color: Theme.textDim

    font.family: Theme.sansFamily
    font.pixelSize: Theme.fontSmall

    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
