import QtQuick
import qs.theme

// The large type: a panel's title, a track's name, the clock. Set in the
// display cut of the same family, which is drawn tighter and with smaller
// apertures for exactly this — type read at a glance rather than a line at a
// time. A session whose face has no display cut gets the one it has.
Text {
    color: Theme.text

    font.family: Theme.displayFamily
    font.pixelSize: Theme.fontTitle
    font.weight: Font.DemiBold

    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
