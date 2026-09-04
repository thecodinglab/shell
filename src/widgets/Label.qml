import QtQuick
import QtQuick.Layouts
import qs.theme

// A name, and the line under it: what a thing is, and how it is doing.
//
// The one arrangement of type every row and tile on the surface is built
// around, so a device, a link, the head of a module and the card of a dial
// all read the same way down the panel. The line is there only when there
// is something to say on it.
ColumnLayout {
    id: root

    property string title: ""
    property string caption: ""
    property color captionColor: Theme.textDim

    spacing: Theme.px(1)

    Sans {
        Layout.fillWidth: true

        text: root.title
        color: Theme.text

        font.weight: Font.Medium
    }

    Caption {
        Layout.fillWidth: true

        visible: text !== ""

        text: root.caption
        color: root.captionColor
    }
}
