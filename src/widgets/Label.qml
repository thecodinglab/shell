import QtQuick
import QtQuick.Layouts
import qs.theme

// A name, and the line under it: what a thing is, and how it is doing.
//
// The one arrangement of type every row on the surface is built
// around, so a device, a link and the head of a section all read the same
// way down the page. The line is there only when there is something to say
// on it.
ColumnLayout {
    id: root

    property Scheme scheme: Theme.schemeOf(root)

    property string title: ""
    property string caption: ""
    property color captionColor: root.scheme.textDim

    spacing: Theme.lineGap

    Sans {
        Layout.fillWidth: true

        scheme: root.scheme
        text: root.title

        font.weight: Font.Medium
    }

    Caption {
        Layout.fillWidth: true

        visible: text !== ""

        scheme: root.scheme
        text: root.caption
        color: root.captionColor
        // captions carry figures — an address, a percentage — and hold
        // still while they tick
        font.features: Theme.tabular
    }
}
