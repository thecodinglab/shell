import QtQuick
import qs.theme

// The small label over a section, or under a figure.
//
// Sentence case and untracked: a label is there to name the thing below it,
// and setting it in spaced capitals makes it louder than what it names while
// also making it slower to read. It is quiet ink instead, which is what tells
// you it is a label.
Text {
    color: Theme.textDim

    font.family: Theme.sansFamily
    font.pixelSize: Theme.fontSmall

    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
