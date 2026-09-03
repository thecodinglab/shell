import QtQuick
import qs.theme

// Body text: names, titles, anything a human wrote. The default face for the
// whole surface — see Title for the sizes that get the display cut, and Num
// for anything that has to hold still while it changes.
Text {
    color: Theme.textBody

    font.family: Theme.sansFamily
    font.pixelSize: Theme.fontBody

    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
