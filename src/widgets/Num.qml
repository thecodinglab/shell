import QtQuick
import qs.theme

// A figure: a percentage, a clock, an address, a track position.
//
// Tabular figures, so every digit is the same width and a number changing
// never moves what is beside it. That is the whole reason this is its own
// component rather than a colour on Sans — anything on the notch that ticks
// is set in one of these, and anything set in one of these can be laid out as
// if its width were fixed, because it is.
Text {
    color: Theme.textMuted

    font.family: Theme.sansFamily
    font.pixelSize: Theme.fontSmall
    font.features: Theme.tabular

    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
