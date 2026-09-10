import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.widgets

// What a notification says, laid out: the sender's mark, the title with who
// it came from beside it, and the body under that. A toast and a row in the
// panel are this same thing on two different grounds.
RowLayout {
    id: root

    property string title: ""
    // who sent it, and on a row in the panel also when
    property string meta: ""
    property string body: ""
    // an image the notification came with, if it did — a path, or the
    // server's own image provider url while the notification is still up
    property string image: ""
    // the sender's icon, by name
    property string icon: ""
    property bool urgent: false
    property int discSize: Theme.discSize

    readonly property string source: root.image || (root.icon ? Quickshell.iconPath(root.icon, true) : "")

    spacing: Theme.space3

    // The mark at the head: the sender's own icon, at its own shape, or a
    // bell on a disc of the accent when it has none. An urgent one sits on
    // the red instead, whatever it carries.
    Item {
        Layout.alignment: Qt.AlignTop

        implicitWidth: root.discSize
        implicitHeight: root.discSize

        ClippingRectangle {
            anchors.fill: parent

            visible: root.source !== ""

            radius: Theme.radiusSmall
            color: "transparent"

            IconImage {
                anchors.fill: parent

                source: root.source
                implicitSize: root.discSize
                asynchronous: true
            }
        }

        Rectangle {
            anchors.fill: parent

            visible: root.source === ""

            radius: width / 2
            color: root.urgent ? Theme.urgentSurface : Theme.accentSurface

            Text {
                anchors.centerIn: parent

                text: Icons.bell
                color: root.urgent ? Theme.urgent : Theme.accent

                font.family: Theme.monoFamily
                font.pixelSize: Math.round(root.discSize * 0.42)
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        spacing: Theme.lineGap

        RowLayout {
            Layout.fillWidth: true

            spacing: Theme.rowSpacing

            Sans {
                Layout.fillWidth: true

                text: root.title

                font.weight: Font.Medium
            }

            Caption {
                text: root.meta
                // when, in figures that hold still as the minutes tick over
                font.features: Theme.tabular
            }
        }

        Sans {
            Layout.fillWidth: true

            visible: text !== ""

            text: root.body
            color: Theme.textMuted

            // the server advertises markup support, so bodies arrive with
            // it in them
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: 3
            lineHeight: 1.35
        }
    }
}
