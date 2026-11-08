pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.notch
import qs.spotlight
import qs.polkit
import qs.power

ShellRoot {
    id: root

    Variants {
        id: notches

        model: Quickshell.screens

        // a notch unfolding, however it was asked to, takes the keyboard, and
        // Spotlight and the power pane go so no two ever both want it
        Notch {
            id: notch

            onExpandedChanged: {
                if (!notch.expanded)
                    return;
                root.closeSpotlights();
                power.open = false;
            }

            // the power mark on its home page, which brings the pane out on
            // this monitor rather than the focused one
            onPowerRequested: root.showPower(notch.modelData)
        }
    }

    // Spotlight on every monitor, put away until it is asked for. A page of
    // the notch picked from it is opened by the notch on the same monitor.
    Variants {
        id: spotlights

        model: Quickshell.screens

        Spotlight {
            id: spotlight

            onPanelRequested: name => root.notchOn(spotlight.modelData)?.open(name)
        }
    }

    // The notch on whichever monitor has focus, which is where anything asked
    // for from the keyboard lands.
    function focused(): var {
        const notch = notches.instances.find(n => Hyprland.monitorFor(n.modelData) === Hyprland.focusedMonitor);
        return notch ?? notches.instances[0] ?? null;
    }

    function notchOn(screen: var): var {
        return notches.instances.find(n => n.modelData === screen) ?? null;
    }

    function closeSpotlights(): void {
        for (const spotlight of spotlights.instances)
            spotlight.open = false;
    }

    // The focused monitor's Spotlight, once everything that could be in its
    // way has been put away: the other monitors' Spotlight, and every notch.
    // None while a password is being asked for: it would take the keyboard
    // from the pane that is asking.
    function clearForSpotlight(): var {
        if (root.authenticating)
            return null;

        power.open = false;
        const notch = root.focused();
        const spotlight = notch ? spotlights.instances.find(s => s.modelData === notch.modelData) : null;
        for (const other of spotlights.instances)
            if (other !== spotlight)
                other.open = false;
        for (const other of notches.instances)
            other.expanded = false;
        return spotlight ?? null;
    }

    function toggleSpotlight(): void {
        const spotlight = root.clearForSpotlight();
        if (spotlight)
            spotlight.toggle();
    }

    // ── authentication ────────────────────────────────────────────────────
    //
    // The polkit agent's pane, one for the whole shell, coming out on the
    // monitor that has focus when something asks for a password. It takes
    // the keyboard while it is out, so whatever had it is put away first:
    // Spotlight closes and every notch folds.
    //
    // It keeps the keyboard for as long as the request is being answered,
    // not only as it arrives: nothing asked for from the keyboard while it
    // is out comes out over it, and a notch unfolded with the pointer
    // leaves the keyboard where it is — see Notch.
    readonly property bool authenticating: Polkit.flow !== null

    Prompt {
        focusedScreen: root.focused()?.modelData ?? null

        onOpened: {
            power.open = false;
            root.closeSpotlights();
            for (const notch of notches.instances)
                notch.expanded = false;
        }
    }

    // ── the ways out ──────────────────────────────────────────────────────
    //
    // The power pane, one for the whole shell, out on the monitor it was
    // asked for on. It takes the keyboard, so Spotlight closes and every
    // notch folds as it comes; and like everything else it stays put while
    // a password is being asked for.
    PowerDialog {
        id: power
    }

    function showPower(screen: var): void {
        if (root.authenticating || !screen)
            return;

        root.closeSpotlights();
        for (const notch of notches.instances)
            notch.expanded = false;
        power.show(screen);
    }

    // ...and from the command line, for a keybind the way a mac's power key
    // brings it up:
    //
    //     qs -p ~/dev/shell/src ipc call power open
    IpcHandler {
        target: "power"

        function open(): void {
            root.showPower(root.focused()?.modelData ?? null);
        }

        function close(): void {
            power.open = false;
        }
    }

    // ── the volume, from the keyboard ─────────────────────────────────────
    //
    // A media key sets the volume through wireplumber, not through the shell,
    // so the shell finds out the way everything else does: pipewire tells it.
    // Any change to the output that was not made on a notch's own slider is
    // announced on the focused monitor. An open notch is showing its slider
    // already, and the change is most likely that slider being dragged, so
    // nothing is announced while one is open anywhere.

    // Pipewire hands over every sink's level as it first connects, which
    // would otherwise announce the volume the moment the shell starts.
    property bool settled: false

    Timer {
        interval: 1000
        running: true

        onTriggered: root.settled = true
    }

    Connections {
        target: Audio

        function onAdjusted(): void {
            if (!root.settled || notches.instances.some(n => n.unfolded))
                return;

            root.focused()?.showVolume();
        }
    }

    // ── bluetooth, from wherever it was asked for ─────────────────────────
    //
    // A device connecting, disconnecting, or done doing either, announced
    // on the focused monitor — or on the one already announcing it, so a
    // connection that is still being made does not jump screens when the
    // focus moves while it is.
    Connections {
        target: Bt

        function onMoved(): void {
            const notch = notches.instances.find(n => n.hailing) ?? root.focused();
            notch?.showDevice(Bt.heard, Bt.failed);
        }
    }

    // Bluetooth from the command line, in place of `bluetoothctl connect`:
    //
    //     qs -p ~/dev/shell/src ipc call bluetooth connect "WH-1000XM4"
    //     qs -p ~/dev/shell/src ipc call bluetooth disconnect 94:DB:56:94:55:D4
    //
    // Bluez has no word for a connection that is still being made, so one
    // started anywhere else is only heard of once it has been — or has
    // failed. Started here, the shell knows it is under way from the first
    // moment, and the announcement above says so for as long as it is.
    // A device is named by its address, its name, or any part of the name
    // that no other device shares; what was done, or why nothing was, is
    // printed back.
    IpcHandler {
        target: "bluetooth"

        function connect(device: string): string {
            const found = Bt.find(device);
            if (!found)
                return `no one device matches "${device}"`;
            if (found.connected)
                return `${Bt.label(found)} is already connected`;
            if (Bt.busy(found))
                return `${Bt.label(found)} is busy: ${Bt.status(found)}`;

            found.connect();
            return `connecting to ${Bt.label(found)}`;
        }

        function disconnect(device: string): string {
            const found = Bt.find(device);
            if (!found)
                return `no one device matches "${device}"`;
            if (!found.connected)
                return `${Bt.label(found)} is not connected`;
            if (Bt.busy(found))
                return `${Bt.label(found)} is busy: ${Bt.status(found)}`;

            found.disconnect();
            return `disconnecting from ${Bt.label(found)}`;
        }
    }

    // The notch from the command line, for a keybind:
    //
    //     qs -p ~/dev/shell/src ipc call notch toggle
    //     qs -p ~/dev/shell/src ipc call notch open audio
    //     qs -p ~/dev/shell/src ipc call notch peek
    //
    // Whichever monitor has focus gets it; `close` folds every one of them.
    // While a password is being asked for, nothing opens: a keybind is
    // the keyboard asking, and the keyboard is the polkit pane's.
    IpcHandler {
        target: "notch"

        function toggle(): void {
            const notch = root.focused();
            if (!notch)
                return;

            root.closeSpotlights();
            if (notch.expanded)
                notch.expanded = false;
            else if (!root.authenticating)
                notch.open("home");
        }

        function open(panel: string): void {
            if (root.authenticating)
                return;

            root.closeSpotlights();
            root.focused()?.open(panel);
        }

        function close(): void {
            root.closeSpotlights();
            for (const notch of notches.instances)
                notch.expanded = false;
        }

        function peek(): void {
            root.focused()?.peek();
        }

        // Put away the newest notification hanging under the notch, as its
        // cross would, for a key rather than the pointer.
        function dismiss(): void {
            Notifs.dismissNewest();
        }
    }

    // Spotlight, for the keybind that used to run a launcher of its own:
    //
    //     qs -p ~/dev/shell/src ipc call spotlight toggle
    //
    // Opens it on the focused monitor, or puts it away if it is already out
    // there. The two never both have the keyboard, so any notch open
    // anywhere folds first. `launcher` is the same call under the name it
    // had when it was a page of the notch, so a bind written for that still
    // works.
    IpcHandler {
        target: "spotlight"

        function toggle(): void {
            root.toggleSpotlight();
        }

        // out on the focused monitor with `text` already typed into it
        function search(text: string): void {
            root.clearForSpotlight()?.search(text);
        }

        // out on the focused monitor on the clipboard history, for a bind
        // of its own
        function clipboard(): void {
            root.clearForSpotlight()?.clipboard();
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggleSpotlight();
        }
    }
}
