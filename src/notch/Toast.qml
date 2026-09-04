import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.theme
import qs.services
import qs.widgets

// A notification, hanging below the collapsed notch.
//
// It leaves on its own after a while, and the clock stops while the pointer
// is on it — the one case where you are demonstrably still reading.
//
// The notification behind it is gone before the toast is: once it is closed
// the server drops the object, and the toast is still on screen fading out.
// So what it shows is bound to the notification only while there is one, and
// held as it was the moment it closed — the card that fades is the card that
// was being read, not a blank one.
Rectangle {
    id: root

    required property var notification

    // there is still a notification behind this toast; false once it has
    // closed, from which point the toast is only on its way out
    property bool live: true

    property bool urgent: root.notification?.urgency === NotificationUrgency.Critical

    property string title: root.notification?.summary || root.notification?.appName || ""
    property string appName: root.notification?.appName ?? ""
    property string body: root.notification?.body ?? ""
    property string image: root.notification?.image ?? ""
    property string icon: root.notification?.appIcon || root.notification?.desktopEntry || ""

    // Keep what it says. Assigning each property its own current value
    // replaces the binding with that value, so nothing changes when the
    // object the binding read from goes away.
    function freeze(): void {
        root.live = false;
        root.urgent = root.urgent;
        root.title = root.title;
        root.appName = root.appName;
        root.body = root.body;
        root.image = root.image;
        root.icon = root.icon;
    }

    implicitHeight: layout.implicitHeight + Theme.cardPadding * 2

    radius: Theme.toastRadius
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
        anchors.margins: Theme.cardPadding

        spacing: Theme.px(12)

        NotifDisc {
            Layout.alignment: Qt.AlignTop

            image: root.image
            icon: root.icon
            urgent: root.urgent
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
                    text: root.appName
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

    MouseArea {
        id: mouse

        anchors.fill: parent
        // a toast on its way out is no longer anything to click on
        enabled: root.live
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        // Left invokes what the notification says it is for, middle always
        // just gets rid of it. Either way it has been dealt with, and does
        // not turn up in the panel afterwards.
        onClicked: event => {
            const actions = root.notification?.actions ?? [];
            const primary = actions.find(a => a.identifier === "default");

            if (event.button === Qt.LeftButton && primary)
                primary.invoke();

            Notifs.dismiss(root.notification);
        }
    }

    // Out of time: off the screen, and into the panel.
    Timer {
        interval: Notifs.timeout(root.notification)
        // reading it holds it there
        running: root.live && !mouse.containsMouse

        onTriggered: Notifs.expire(root.notification)
    }

    // Closed, whether by the clock, a click, or the sending application
    // taking it back: hold what it shows, and leave.
    Connections {
        target: root.notification

        function onClosed(reason: int): void {
            root.freeze();
            Notifs.remove(root.notification);
        }
    }
}
