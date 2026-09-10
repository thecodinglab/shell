import QtQuick
import qs.theme

// The name over a section of a page: "Output", "Apps", "Input". The body
// size a step heavier, so it reads as the heading of what is under it rather
// than as a footnote to it.
Text {
    color: Theme.text

    font.family: Theme.sansFamily
    font.pixelSize: Theme.fontBody
    font.weight: Font.Medium

    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
