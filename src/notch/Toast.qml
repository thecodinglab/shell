import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.theme
import qs.services
import qs.widgets

// A notification, hanging below the collapsed notch.
//
// It leaves on its own after a while, and the clock stops while the pointer
// is on it — the one case where you are demonstrably still reading.
Rectangle {
    id: root

    required property var notification

    readonly property bool urgent: root.notification.urgency === NotificationUrgency.Critical

    readonly property string iconSource: {
        if (root.notification.image)
            return root.notification.image;

        const name = root.notification.appIcon || root.notification.desktopEntry;
        return name ? Quickshell.iconPath(name, true) : "";
    }

    implicitHeight: layout.implicitHeight + Theme.px(11) * 2

    radius: Theme.cardRadius
    color: root.urgent ? Theme.slabUrgent : Theme.slab

    border.width: 1
    border.color: root.urgent ? Theme.urgentBorder : Theme.slabBorder

    // it hangs over the desktop on its own, so it casts its own shadow
    Shadow {
        target: root
        radius: root.radius
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Theme.px(11)

        spacing: Theme.rowSpacing

        Rectangle {
            Layout.alignment: Qt.AlignTop

            implicitWidth: Theme.px(28)
            implicitHeight: Theme.px(28)

            radius: Theme.px(8)
            color: root.urgent ? Theme.urgentSurface : Theme.accentSurface

            IconImage {
                anchors.centerIn: parent

                visible: root.iconSource !== ""

                source: root.iconSource
                implicitSize: Theme.px(18)
                asynchronous: true
            }

            Text {
                anchors.centerIn: parent

                visible: root.iconSource === ""

                text: Icons.bell
                color: root.urgent ? Theme.urgent : Theme.accent

                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontBody
            }
        }

        ColumnLayout {
            Layout.fillWidth: true

            spacing: Theme.px(2)

            RowLayout {
                Layout.fillWidth: true

                spacing: Theme.rowSpacing

                Sans {
                    Layout.fillWidth: true

                    text: root.notification.summary || root.notification.appName
                    color: Theme.text

                    font.weight: Font.DemiBold
                }

                Mono {
                    text: root.notification.appName
                }
            }

            Sans {
                Layout.fillWidth: true

                visible: text !== ""

                text: root.notification.body
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

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        // left invokes what the notification says it is for, middle always
        // just gets rid of it
        onClicked: event => {
            const actions = root.notification.actions ?? [];
            const primary = actions.find(a => a.identifier === "default");

            if (event.button === Qt.LeftButton && primary)
                primary.invoke();

            Notifs.dismiss(root.notification);
        }
    }

    Timer {
        interval: Notifs.timeout(root.notification)
        // reading it holds it there
        running: !mouse.containsMouse

        onTriggered: Notifs.dismiss(root.notification)
    }

    // the sending application can take it back at any point
    Connections {
        target: root.notification

        function onClosed(reason: int): void {
            Notifs.remove(root.notification);
        }
    }
}
