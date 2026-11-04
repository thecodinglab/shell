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
    // the sender's icon, by name or by path
    property string icon: ""
    property bool urgent: false
    property int discSize: Theme.discSize
    property int badgeSize: Theme.toastBadgeSize

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

    // The pointer is anywhere on it, over one of its buttons or not, which
    // a row uses to keep its ground lit while the pointer is on a button
    // that has taken the hover from it.
    readonly property bool pointed: hover.hovered
    // the keyboard is on the cross, which brings it out as the pointer does
    readonly property bool crossFocused: cross.activeFocus

    property Scheme scheme: Theme.schemeOf(root)

    // one of `actions` was pressed, or the cross was
    signal acted(var action)
    signal dismissed

    // An icon the theme does not have. The server hands an `image-path`
    // that is an icon's name over as a request to the icon provider without
    // asking the theme first, and a request for one it does not have draws
    // the missing-texture checkerboard; asked first, it is nothing, and the
    // bell stands in. A path, in the request or on its own, is left alone.
    function resolve(source: string): string {
        if (source === "")
            return "";
        const request = "image://icon/";
        if (source.startsWith(request)) {
            const name = source.slice(request.length).split("?")[0];
            return name.startsWith("/") ? source : Quickshell.iconPath(name, true);
        }
        // a file, as a path or as a url with one slash or three, or any
        // other url — the server's own for an image it was sent as data
        if (source.startsWith("/") || source.startsWith("file:") || source.includes("://"))
            return source;
        return Quickshell.iconPath(source, true);
    }

    readonly property string picture: root.resolve(root.image)
    readonly property string mark: root.resolve(root.icon)
    // what stands at the head: what it brought, or failing that its sender
    readonly property string source: root.picture || root.mark
    // and the sender on its shoulder, when what it brought is something else
    readonly property bool badged: root.picture !== "" && root.mark !== "" && root.picture !== root.mark

    spacing: Theme.space3

    HoverHandler {
        id: hover
    }

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

        // The sender on the shoulder of what it brought, overhanging the
        // corner by its rim, which is the bezel's own ground: it reads as
        // laid on the picture rather than as part of it.
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: -Theme.badgeRim

            visible: root.badged

            width: root.badgeSize + Theme.badgeRim * 2
            height: width
            radius: Theme.badgeRim * 2
            color: root.scheme.ground

            IconImage {
                anchors.centerIn: parent

                source: root.badged ? root.mark : ""
                implicitSize: root.badgeSize
                asynchronous: true
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        spacing: Theme.lineGap

        // A critical one says so, in words and with a mark, over its title:
        // it does not go on its own, and the red alone would be telling it
        // by colour to anyone who can tell red apart. The red is ink here,
        // the way it is on a workspace asking for attention, rather than a
        // ground laid under the toast.
        RowLayout {
            Layout.fillWidth: true

            visible: root.urgent

            spacing: Theme.space1

            Text {
                text: Icons.alert
                color: root.scheme.urgent

                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontSmall
            }

            Caption {
                Layout.fillWidth: true

                scheme: root.scheme
                text: "Critical"
                color: root.scheme.urgent

                font.weight: Font.Medium
            }
        }

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
                // than its mark, so the mark ends where the meta did. Hidden
                // by its ink rather than taken away, so the keyboard can
                // still reach it, and reaching it brings it out.
                IconButton {
                    id: cross

                    anchors.right: parent.right
                    anchors.rightMargin: -(Theme.actionSize - Theme.fontBody) / 2
                    anchors.verticalCenter: parent.verticalCenter

                    visible: root.dismissable
                    opacity: root.offered ? 1 : 0

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
