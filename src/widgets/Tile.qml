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
    property string title: ""
    property string subtitle: ""
    property color subtitleColor: Theme.textDim

    padding: Theme.cardPadding

    IconDisc {
        Layout.alignment: Qt.AlignVCenter

        icon: root.icon
        on: root.on
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

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

            text: root.subtitle
            color: root.subtitleColor
        }
    }
}
