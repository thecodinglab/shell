pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.notch

ShellRoot {
    id: root

    Variants {
        id: notches

        model: Quickshell.screens

        Notch {}
    }

    // The notch on whichever monitor has focus, which is where anything asked
    // for from the keyboard lands.
    function focused(): var {
        const notch = notches.instances.find(n => Hyprland.monitorFor(n.modelData) === Hyprland.focusedMonitor);
        return notch ?? notches.instances[0] ?? null;
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

    // The notch from the command line, for a keybind:
    //
    //     qs -p ~/dev/shell/src ipc call notch toggle
    //     qs -p ~/dev/shell/src ipc call notch open audio
    //     qs -p ~/dev/shell/src ipc call notch peek
    //
    // Whichever monitor has focus gets it; `close` folds every one of them.
    IpcHandler {
        target: "notch"

        function toggle(): void {
            const notch = root.focused();
            if (!notch)
                return;

            if (notch.expanded)
                notch.expanded = false;
            else
                notch.open("home");
        }

        function open(panel: string): void {
            root.focused()?.open(panel);
        }

        function close(): void {
            for (const notch of notches.instances)
                notch.expanded = false;
        }

        function peek(): void {
            root.focused()?.peek();
        }
    }
}
