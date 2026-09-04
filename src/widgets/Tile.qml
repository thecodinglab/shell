import QtQuick
import QtQuick.Layouts
import qs.theme

// A door on the home panel: a disc, what it leads to, and one line on how
// that is doing right now.
//
// The whole tile is the button, so it carries no chevron — a filled ground
// that lightens under the pointer is affordance enough, and a chevron in
// the corner of every tile is a row of them across the panel.
ListRow {
    id: root

    property string icon: ""
    property bool on: false
    property alias title: label.title
    property alias caption: label.caption
    property alias captionColor: label.captionColor

    padding: Theme.cardPadding

    IconDisc {
        Layout.alignment: Qt.AlignVCenter

        icon: root.icon
        on: root.on
    }

    Label {
        id: label

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
    }
}
