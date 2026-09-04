pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config

// The notification server, the short queue of what is currently hanging
// below the notch, and the longer one of what has come in and not been
// dealt with, which is what the notifications panel shows.
//
// The two are different things. A toast is the Notification object itself,
// and lives exactly as long as the server keeps it: dismissing one closes
// the notification for real, so the sending application knows it is gone.
// The panel holds a record of each one instead — what it said, when — that
// is written to disk as it changes, so what was waiting before the shell
// restarted is still waiting after. A record leaves when it is dismissed,
// when the application takes the notification back, or on its own once it
// is older than `Config.notificationRetention`.
Singleton {
    id: root

    // ── on screen ─────────────────────────────────────────────────────────

    // newest first, which is the order they stack downwards in
    property var toasts: []
    readonly property int visibleCount: 3

    // Gone from the screen because its time ran out. The notification is
    // told so; the record stays for the panel.
    function expire(notification: Notification): void {
        // The same toast hangs under every monitor's notch, each with a clock
        // of its own: the first to run out closes it, and the rest find it
        // already gone. Closing it a second time is an error.
        if (!root.toasts.includes(notification))
            return;

        root.remove(notification);
        notification.expire();
    }

    // Gone from the screen because you got rid of it, which is also how the
    // notification is closed — and having been got rid of, it has no
    // business turning up again in the panel.
    function dismiss(notification: Notification): void {
        if (!root.toasts.includes(notification))
            return;

        root.remove(notification);
        root.forget(root.recordOf(notification));
        notification.dismiss();
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

    // ── kept ──────────────────────────────────────────────────────────────

    // What the panel shows, newest first. Each is a `Record`: an object of
    // its own rather than the Notification, which the server drops the
    // moment it closes, and rather than a plain dictionary, so that a
    // notification an application updates in place — a download counting
    // up — updates the row it is on rather than replacing it.
    property var kept: []
    readonly property int count: root.kept.length

    // The record for each notification still open, so an update to the one
    // lands on the other, and so a click on a record can still invoke what
    // the notification was for while there is one to invoke it on.
    readonly property var live: new Map()

    component Record: QtObject {
        required property string key
        // milliseconds since the epoch
        required property real time
        property string appName: ""
        property string summary: ""
        property string body: ""
        property string appIcon: ""
        property string desktopEntry: ""
        // a path, or while the notification is up possibly an image provider
        // url, which is meaningless after a restart and not written
        property string image: ""
        property bool urgent: false
    }

    Component {
        id: recordComponent

        Record {}
    }

    function recordOf(notification: Notification): Record {
        return root.live.get(notification) ?? null;
    }

    // Which record a notification writes into: its own if it has one, or a
    // fresh one at the top of the list.
    function keep(notification: Notification): void {
        let record = root.recordOf(notification);

        if (!record) {
            const time = Date.now();
            record = recordComponent.createObject(root, {
                key: `${time.toString(36)}-${notification.id}`,
                time: time
            });
            root.live.set(notification, record);
            root.trim([record, ...root.kept]);
        }

        record.appName = notification.appName ?? "";
        record.summary = notification.summary ?? "";
        record.body = notification.body ?? "";
        record.appIcon = notification.appIcon ?? "";
        record.desktopEntry = notification.desktopEntry ?? "";
        record.image = notification.image ?? "";
        record.urgent = notification.urgency === NotificationUrgency.Critical;

        root.save();
    }

    // Let go of a record's object. It lingers a moment longer than the list
    // does: a row on its way out is still reading from it while it fades.
    function release(record: Record): void {
        for (const [notification, r] of root.live)
            if (r === record)
                root.live.delete(notification);

        record.destroy(1000);
    }

    // Make `records` the list, less whatever is over the cap at the end.
    function trim(records: var): void {
        root.kept = records.slice(0, Config.notificationLimit);
        for (const record of records.slice(Config.notificationLimit))
            root.release(record);
    }

    // Take a record out of the list.
    function forget(record: Record): void {
        if (!record || !root.kept.includes(record))
            return;

        root.kept = root.kept.filter(r => r !== record);
        root.release(record);
        root.save();
    }

    function clear(): void {
        for (const record of [...root.kept])
            root.forget(record);
    }

    // What a click on a record does: what the notification said it was for,
    // if it is still up to say so, and failing that the application it came
    // from. Either way the record is dealt with.
    function open(record: Record): void {
        let notification = null;
        for (const [n, r] of root.live)
            if (r === record)
                notification = n;

        const primary = notification?.actions?.find(a => a.identifier === "default") ?? null;
        if (primary)
            primary.invoke();
        else if (record.desktopEntry)
            DesktopEntries.heuristicLookup(record.desktopEntry)?.execute();

        root.forget(record);

        if (notification) {
            root.remove(notification);
            notification.dismiss();
        }
    }

    // Drop whatever has been waiting longer than it is kept for.
    function sweep(): void {
        const cutoff = Date.now() - Config.notificationRetention * 1000;
        for (const record of root.kept.filter(r => r.time < cutoff))
            root.forget(record);
    }

    Timer {
        interval: 60 * 1000
        repeat: true
        running: root.count > 0

        onTriggered: root.sweep()
    }

    // ── on disk ───────────────────────────────────────────────────────────
    //
    // Under the session's state directory, by the shell's own name rather
    // than quickshell's: quickshell keys its own directories by the path the
    // shell runs from, which the nix build changes on every rebuild.

    readonly property string storePath: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/shell/notifications.json`

    function serialize(record: Record): var {
        return {
            key: record.key,
            time: record.time,
            appName: record.appName,
            summary: record.summary,
            body: record.body,
            appIcon: record.appIcon,
            desktopEntry: record.desktopEntry,
            image: record.image.startsWith("image://") ? "" : record.image,
            urgent: record.urgent
        };
    }

    // Written a moment after the last change rather than on each one, so a
    // burst of notifications is one write.
    function save(): void {
        flush.restart();
    }

    Timer {
        id: flush

        interval: 250

        onTriggered: store.setText(JSON.stringify(root.kept.map(root.serialize)))
    }

    // What the last run left behind, under anything that has already arrived
    // in this one. The file is read once, at startup; from then on this is
    // the only writer.
    function restore(text: string): void {
        let entries = [];
        try {
            entries = JSON.parse(text);
        } catch (e) {
            console.warn(`${root.storePath} is not valid json, starting over: ${e}`);
        }
        if (!Array.isArray(entries))
            entries = [];

        const known = new Set(root.kept.map(r => r.key));
        const restored = [];
        for (const entry of entries) {
            if (typeof entry?.key !== "string" || typeof entry?.time !== "number" || known.has(entry.key))
                continue;

            restored.push(recordComponent.createObject(root, {
                key: entry.key,
                time: entry.time,
                appName: String(entry.appName ?? ""),
                summary: String(entry.summary ?? ""),
                body: String(entry.body ?? ""),
                appIcon: String(entry.appIcon ?? ""),
                desktopEntry: String(entry.desktopEntry ?? ""),
                image: String(entry.image ?? ""),
                urgent: Boolean(entry.urgent)
            }));
        }

        root.trim([...root.kept, ...restored].sort((a, b) => b.time - a.time));
        root.sweep();
    }

    FileView {
        id: store

        path: root.storePath
        atomicWrites: true
        // the shell is the only thing that writes this file
        watchChanges: false
        // a missing file is the first run
        printErrors: false

        onLoaded: root.restore(store.text())
    }

    // ── the server ────────────────────────────────────────────────────────

    NotificationServer {
        keepOnReload: false

        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            // without this the server drops it the moment this handler returns
            notification.tracked = true;
            root.toasts = [notification, ...root.toasts].slice(0, root.visibleCount);

            // One marked transient is the sender asking for exactly this: a
            // volume step, a track change — shown, and not kept.
            if (notification.transient)
                return;

            root.keep(notification);

            // An application replacing what it said — a download counting
            // up — updates the same notification rather than sending a new
            // one, and the record follows it.
            const refresh = () => root.keep(notification);
            notification.summaryChanged.connect(refresh);
            notification.bodyChanged.connect(refresh);
            notification.appIconChanged.connect(refresh);
            notification.imageChanged.connect(refresh);
            notification.urgencyChanged.connect(refresh);

            // Closed by the application itself, the notification no longer
            // applies and neither does the record. Closed because its time
            // ran out, the record is the point. Closed because it was
            // dismissed, the record has already gone — see `dismiss`.
            notification.closed.connect(reason => {
                if (reason === NotificationCloseReason.CloseRequested)
                    root.forget(root.recordOf(notification));
                root.live.delete(notification);
            });
        }
    }
}
