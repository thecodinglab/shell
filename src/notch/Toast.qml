import QtQuick
import Quickshell.Services.Notifications
import qs.theme
import qs.services

// A notification, opening out of the top edge as more of the notch: the
// bezel rather than glass, laid straight onto the ground of the stack it is
// one of — see `Notch.stack` — with nothing between it and the one above but
// a hairline. The stack draws the ground, the shadow and the corners; this
// is only what is on them.
//
// It leaves on its own after a while, and the clock stops while the pointer
// is on it — the one case where you are demonstrably still reading. A
// critical one has no clock at all: it is there until it has been dealt
// with, by a click, its cross, or one of what it offers to do. A warning
// that went away on its own while you were looking elsewhere would be one
// you never had.
//
// The notification behind it is gone before the toast is: once it is closed
// the server drops the object, and the toast is still on screen fading out.
// So what it shows is bound to the notification only while there is one, and
// held as it was the moment it closed — the card that fades is the card that
// was being read, not a blank one.
Item {
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

    // how tall it was when it closed — see `freeze`
    property real held: 0

    // Keep what it says. Assigning each property its own current value
    // replaces the binding with that value, so nothing changes when the
    // object the binding read from goes away. It keeps its height too: what
    // it offered to do goes with the notification, and its place in the
    // stack closes up from the height it had rather than jumping short by a
    // row of buttons first. Once is enough; a second time it would measure
    // itself without them.
    function freeze(): void {
        if (!root.live)
            return;
        root.held = root.implicitHeight;
        root.live = false;
        root.urgent = root.urgent;
        root.title = root.title;
        root.appName = root.appName;
        root.body = root.body;
        root.image = root.image;
        root.icon = root.icon;
    }

    implicitHeight: root.live ? content.implicitHeight + Theme.toastPadding * 2 : root.held

    Accessible.role: Accessible.AlertMessage
    Accessible.name: root.title
    Accessible.description: root.body

    // An urgent one is told by its ground: a wash of the red under
    // everything on it, inset from the stack's edges and concentric with its
    // corners, so the outline of the stack stays the bezel's all the way
    // round and into the ears, wherever in it the urgent one is.
    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.toastPadding / 2

        visible: root.urgent

        radius: Theme.toastRadius - Theme.toastPadding / 2
        color: Theme.bezel.urgentSurface
    }

    // The pointer anywhere on it, over a button on it or not: what holds the
    // clock, and what brings out the cross. A handler rather than the mouse
    // area below, which the buttons in front of it take the hover from.
    HoverHandler {
        id: hover
    }

    // Under the content, so the buttons on it get their clicks first and
    // only a click on the rest of the toast is a click on the toast.
    MouseArea {
        id: mouse

        anchors.fill: parent
        // a toast on its way out is no longer anything to click on
        enabled: root.live
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        // Left invokes what the notification says it is for, middle always
        // just gets rid of it. Either way it has been dealt with, and does
        // not turn up in the panel afterwards.
        onClicked: event => {
            const actions = root.notification?.actions ?? [];
            const primary = actions.find(a => a.identifier === "default");

            if (event.button === Qt.LeftButton && primary)
                Notifs.act(root.notification, primary);
            else
                Notifs.dismiss(root.notification);
        }
    }

    NotifContent {
        id: content

        // from the top rather than filling it, so that what is left once
        // the buttons have gone stays where it was — see `freeze`
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.toastPadding

        title: root.title
        meta: root.appName
        body: root.body
        image: root.image
        icon: root.icon
        urgent: root.urgent
        discSize: Theme.toastIconSize

        // What it offers to do besides being opened, which the click on the
        // toast itself already does: a capsule each, and no more than three
        // of them, which with the click makes the four a mac allows one.
        actions: (root.notification?.actions ?? []).filter(a => a.identifier !== "default").slice(0, 3)
        live: root.live

        dismissable: true
        offered: root.live && hover.hovered

        // Doing what it offered is dealing with it too: it goes, and does
        // not turn up in the panel afterwards.
        onActed: action => Notifs.act(root.notification, action)
        onDismissed: Notifs.dismiss(root.notification)
    }

    // Out of time: off the screen, and into the panel. A critical one has no
    // time to run out of — see `Notifs.timeout`.
    Timer {
        interval: Notifs.timeout(root.notification)
        // reading it holds it there
        running: root.live && !hover.hovered && interval > 0

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
