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

    spacing: Theme.px(12)

    // The mark at the head: the sender's own icon on a disc, or a bell on the
    // accent's when it has none. An urgent one sits on the red instead,
    // whatever it carries.
    Rectangle {
        Layout.alignment: Qt.AlignTop

        implicitWidth: root.discSize
        implicitHeight: root.discSize

        radius: width / 2
        color: {
            if (root.urgent)
                return Theme.urgentSurface;
            return root.source !== "" ? Theme.surfaceRaised : Theme.accentSurface;
        }

        IconImage {
            anchors.centerIn: parent

            visible: root.source !== ""

            source: root.source
            implicitSize: Math.round(root.discSize * 0.6)
            asynchronous: true
        }

        Text {
            anchors.centerIn: parent

            visible: root.source === ""

            text: Icons.bell
            color: root.urgent ? Theme.urgent : Theme.accent

            font.family: Theme.monoFamily
            font.pixelSize: Math.round(root.discSize * 0.4)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        spacing: Theme.px(2)

        RowLayout {
            Layout.fillWidth: true

            spacing: Theme.rowSpacing

            Sans {
                Layout.fillWidth: true

                text: root.title
                color: Theme.text

                font.weight: Font.Medium
            }

            Caption {
                text: root.meta
                color: Theme.textFaint
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
