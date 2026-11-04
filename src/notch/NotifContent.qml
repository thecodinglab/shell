pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.widgets

// What a notification says, laid out: the sender's mark, the title with who
// it came from beside it, the body under that, and under the body whatever
// the notification offers to do. A toast and a row in the panel are this
// same thing in two places, both on the bezel, and it takes its colours
// from whatever it is standing on.
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

    // What it offers to do besides being opened, as the server hands them
    // over: a button each, up to the three a toast has room for, set out
    // under the body while there is still a notification to do them to.
    property var actions: []
    // there is still a notification behind this; false once it has closed
    property bool live: true
    // A cross in the meta's place, to get rid of it: room is kept for it,
    // and while `offered` it stands where the meta was, so the line it is on
    // does not move when it comes and goes.
    property bool dismissable: false
    property bool offered: false

    property Scheme scheme: Theme.schemeOf(root)

    // one of `actions` was pressed, or the cross was
    signal acted(var action)
    signal dismissed

    readonly property string source: root.image || (root.icon ? Quickshell.iconPath(root.icon, true) : "")

    spacing: Theme.space3

    // The mark at the head: the sender's own icon, at its own shape, or a
    // bell on a plain disc when it has none — a notification is not "on".
    // An urgent one sits on the red instead, whatever it carries.
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

        IconDisc {
            anchors.fill: parent

            visible: root.source === ""

            scheme: root.scheme
            icon: Icons.bell
            danger: root.urgent
            size: root.discSize
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

                scheme: root.scheme
                text: root.title

                font.weight: Font.Medium
            }

            Item {
                Layout.alignment: Qt.AlignVCenter

                implicitWidth: root.dismissable ? Math.max(meta.implicitWidth, Theme.actionSize) : meta.implicitWidth
                implicitHeight: meta.implicitHeight

                Caption {
                    id: meta

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    opacity: root.dismissable && root.offered ? 0 : 1

                    scheme: root.scheme
                    text: root.meta
                    // when, in figures that hold still as the minutes tick over
                    font.features: Theme.tabular
                }

                // Taller than the line it stands on, so it hangs over the
                // padding above and the line below rather than pushing them
                // apart, and out to the right by as much as its disc is wider
                // than its mark, so the mark ends where the meta did.
                IconButton {
                    anchors.right: parent.right
                    anchors.rightMargin: -(Theme.actionSize - Theme.fontBody) / 2
                    anchors.verticalCenter: parent.verticalCenter

                    visible: root.dismissable && root.offered

                    scheme: root.scheme
                    icon: Icons.close
                    label: "Dismiss"

                    onClicked: root.dismissed()
                }
            }
        }

        Sans {
            Layout.fillWidth: true

            visible: text !== ""

            scheme: root.scheme
            text: root.body
            color: root.scheme.textMuted

            // the server advertises markup support, so bodies arrive with
            // it in them
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: 3
            lineHeight: 1.35
        }

        Flow {
            Layout.fillWidth: true
            Layout.topMargin: Theme.space2

            visible: root.live && root.actions.length > 0

            spacing: Theme.space2

            Repeater {
                model: root.live ? root.actions : []

                Button {
                    id: action

                    required property var modelData

                    scheme: root.scheme
                    text: action.modelData.text

                    onClicked: root.acted(action.modelData)
                }
            }
        }
    }
}
