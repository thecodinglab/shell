import QtQuick
import qs.theme

// The name over a section of a page: "Output", "Apps", "Input". The body
// size, a step heavier than the names in the rows under it, so it reads as
// the heading of what is under it rather than as one more of them.
Text {
    id: root

    property Scheme scheme: Theme.schemeOf(root)

    color: root.scheme.text

    font.family: Theme.sansFamily
    font.pixelSize: Theme.fontBody
    font.weight: Font.DemiBold

    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
