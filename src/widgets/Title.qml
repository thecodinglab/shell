import QtQuick
import qs.theme

// The large type: a page's title, the clock. Set in the display cut of the
// same family, which is drawn tighter and with smaller apertures for exactly
// this — type read at a glance rather than a line at a time.
Text {
    color: Theme.text

    font.family: Theme.displayFamily
    font.pixelSize: Theme.fontTitle
    font.weight: Font.DemiBold
    font.letterSpacing: -Theme.fontTitle * 0.01

    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
