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
// on screen for a while. The panel holds a record of each one — what it
// said, when — that is written to disk as it changes, so what was waiting
// before the shell restarted is still waiting after. A toast that runs out
// of time leaves the screen but not the server: the notification stays open
// behind its record, so what it offered to do can still be done from the
// panel, the way a notification centre keeps a notification's buttons. It
// is closed when it is dealt with — a click, its cross, one of its actions,
// on the toast or on the row — or when the record goes on its own, once it
// is older than `Config.notificationRetention` or pushed off the end of the
// list. Dealing with one tells the sending application it was dismissed;
// one that went on its own is told it expired.
Singleton {
    id: root

    // ── on screen ─────────────────────────────────────────────────────────

    // newest first, which is the order they stack downwards in
    property var toasts: []
    readonly property int visibleCount: 3

    // Gone from the screen because its time ran out. One with a record stays
    // open behind it, for the panel; one that nothing keeps — a transient
    // one — is told it has expired.
    function expire(notification: Notification): void {
        // The same toast hangs under every monitor's notch, each with a clock
        // of its own: the first to run out takes it down, and the rest find
        // it already gone.
        if (!root.toasts.includes(notification))
            return;

        root.remove(notification);
        if (!root.recordOf(notification))
            root.end(notification, true);
    }

    // Gone because you got rid of it, from the toast: closed for real, so
    // the sending application knows, and having been got rid of it has no
    // business turning up again in the panel.
    function dismiss(notification: Notification): void {
        const record = root.recordOf(notification);
        if (record)
            root.forget(record);
        else
            root.end(notification, false);
    }

    // Gone because you did what it offered, from the toast or from its row,
    // which deals with it the same way. The record is taken first: an action
    // on a notification that is not resident closes it there and then, which
    // takes it out of `live` before `dismiss` would find it there.
    function act(notification: Notification, action: var): void {
        const record = root.recordOf(notification);
        action.invoke();
        if (record)
            root.forget(record);
        else
            root.end(notification, false);
    }

    // The newest toast on screen, put away as its cross would — for a key.
    function dismissNewest(): void {
        if (root.toasts.length > 0)
            root.dismiss(root.toasts[0]);
    }

    function remove(notification: Notification): void {
        if (root.toasts.includes(notification))
            root.toasts = root.toasts.filter(n => n !== notification);
    }

    // The notifications the server still has open. Each is closed once and
    // only once: by the time a second way of closing it gets to it — two
    // monitors, an action that closed it already — it is no longer here.
    readonly property var unclosed: new Set()

    // Close a notification, telling the application it expired or that it
    // was dismissed, and take it off the screen if it is on it.
    function end(notification: Notification, expired: bool): void {
        if (!notification || !root.unclosed.has(notification))
            return;

        root.unclosed.delete(notification);
        root.remove(notification);
        if (expired)
            notification.expire();
        else
            notification.dismiss();
    }

    // Put a new one at the head of the stack. With no room left, the oldest
    // that would have gone on its own goes early, into the panel — the new
    // one itself, when everything else up is critical. A critical one has
    // no clock to go on, and is only pushed off by more critical ones than
    // there is room for: otherwise a burst of chatter would take it off the
    // screen before anybody had dealt with it.
    function admit(notification: Notification): void {
        const toasts = [notification, ...root.toasts];
        while (toasts.length > root.visibleCount) {
            let last = toasts.length - 1;
            for (let i = last; i >= 0; i--) {
                if (toasts[i].urgency !== NotificationUrgency.Critical) {
                    last = i;
                    break;
                }
            }
            toasts.splice(last, 1);
        }
        root.toasts = toasts;
    }

    // How long this notification is allowed to sit there, or 0 for until it
    // is dealt with. A critical one stays: something that has gone wrong
    // should not be gone again before anybody has looked up, and it leaves
    // when it is clicked or dismissed. Any other sender asking for zero
    // means "until dismissed" too, which the notch does not offer them;
    // anything else is capped so a stuck application cannot own the screen.
    function timeout(notification: Notification): int {
        if (notification?.urgency === NotificationUrgency.Critical)
            return 0;

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
        // the notification behind it while it is still open, which is what
        // a row does what it offers to; nothing once it has closed, and
        // nothing for a record read back from disk. Untyped, because the
        // type info has no type for the actions on one.
        property var notification: null
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
            record.notification = notification;
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

    // Let go of a record's object, and close the notification still open
    // behind it, as having expired or as dismissed. The object lingers a
    // moment longer than the list does: a row on its way out is still
    // reading from it while it fades.
    function release(record: Record, expired: bool): void {
        const notification = record.notification;
        record.notification = null;
        if (notification)
            root.live.delete(notification);
        root.end(notification, expired);

        record.destroy(1000);
    }

    // Make `records` the list, less whatever is over the cap at the end,
    // which went on its own rather than being dealt with.
    function trim(records: var): void {
        root.kept = records.slice(0, Config.notificationLimit);
        for (const record of records.slice(Config.notificationLimit))
            root.release(record, true);
    }

    // Take a record out of the list, as dealt with.
    function forget(record: Record): void {
        root.drop(record, false);
    }

    // ...or as having gone on its own, when `expired`.
    function drop(record: Record, expired: bool): void {
        if (!record || !root.kept.includes(record))
            return;

        root.kept = root.kept.filter(r => r !== record);
        root.release(record, expired);
        root.save();
    }

    function clear(): void {
        for (const record of [...root.kept])
            root.forget(record);
    }

    // What a click on a record does: what the notification said it was for,
    // if it is still up to say so, and failing that the application it came
    // from. The record stays: opening something is not the same as being
    // done with it, and the cross is there for that.
    function open(record: Record): void {
        const primary = record.notification?.actions?.find(a => a.identifier === "default") ?? null;
        if (primary)
            primary.invoke();
        else if (record.desktopEntry)
            Apps.start(DesktopEntries.heuristicLookup(record.desktopEntry));
    }

    // Drop whatever has been waiting longer than it is kept for.
    function sweep(): void {
        const cutoff = Date.now() - Config.notificationRetention * 1000;
        for (const record of root.kept.filter(r => r.time < cutoff))
            root.drop(record, true);
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
            root.unclosed.add(notification);

            // However it closed — dealt with here, by its own clock, or taken
            // back by the application — it is no longer anything to show or
            // to close, and its record no longer has anything behind it.
            // Taken back by the application, the record no longer applies
            // either; closed because it was dealt with, the record has
            // already gone — see `forget`. A record whose notification went
            // on its own is the point of keeping records, and stays.
            notification.closed.connect(reason => {
                const record = root.recordOf(notification);
                root.unclosed.delete(notification);
                root.live.delete(notification);
                root.remove(notification);
                if (!record)
                    return;

                record.notification = null;
                if (reason === NotificationCloseReason.CloseRequested)
                    root.forget(record);
            });

            root.admit(notification);

            // One marked transient is the sender asking for exactly this: a
            // volume step, a track change — shown, and not kept.
            if (notification.transient)
                return;

            root.keep(notification);

            // An application replacing what it said — a download counting
            // up — updates the same notification rather than sending a new
            // one, and the record follows it. One whose toast has already
            // gone is still open behind its row, so the server hands the
            // update to it rather than announcing a new one: a change in what
            // it says brings it back to the screen, as a new notification
            // would have come, and a change of icon alone does not.
            const refresh = () => root.keep(notification);
            const renew = () => {
                root.keep(notification);
                if (!root.toasts.includes(notification))
                    root.admit(notification);
            };
            notification.summaryChanged.connect(renew);
            notification.bodyChanged.connect(renew);
            notification.appIconChanged.connect(refresh);
            notification.imageChanged.connect(refresh);
            notification.urgencyChanged.connect(refresh);
        }
    }
}
