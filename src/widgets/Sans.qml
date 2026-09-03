import QtQuick
import qs.theme

// Body text: names, titles, anything a human wrote.
Text {
    color: Theme.textBody

    font.family: Theme.sansFamily
    font.pixelSize: Theme.fontBody

    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
