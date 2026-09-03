pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

// The notification server, and the short queue of what is currently hanging
// below the notch.
//
// Nothing is kept after it leaves the screen: this is a shell, not a
// notification centre. Dismissing a toast closes the notification for real,
// so the sending application knows it is gone.
Singleton {
    id: root

    // newest first, which is the order they stack downwards in
    property var toasts: []
    readonly property int visibleCount: 3

    function dismiss(notification: Notification): void {
        root.remove(notification);
        // `dismiss` reports "the user got rid of it", which is what happened
        notification?.dismiss();
    }

    function remove(notification: Notification): void {
        root.toasts = root.toasts.filter(n => n !== notification);
    }

    // How long this notification is allowed to sit there. A sender asking for
    // zero means "until dismissed", which the notch does not offer; anything
    // else is capped so a stuck application cannot own the screen.
    function timeout(notification: Notification): int {
        const asked = notification?.expireTimeout ?? -1;
        if (asked <= 0)
            return Config.notificationTimeout;
        return Math.min(asked, Config.notificationTimeout);
    }

    NotificationServer {
        keepOnReload: false

        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            // without this the server drops it the moment this handler returns
            notification.tracked = true;
            root.toasts = [notification, ...root.toasts].slice(0, root.visibleCount);
        }
    }
}
