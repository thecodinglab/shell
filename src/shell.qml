pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.notch
import qs.spotlight
import qs.polkit

ShellRoot {
    id: root

    Variants {
        id: notches

        model: Quickshell.screens

        // a notch unfolding, however it was asked to, takes the keyboard, and
        // Spotlight goes so the two never both want it
        Notch {
            id: notch

            onExpandedChanged: {
                if (notch.expanded)
                    root.closeSpotlights();
            }
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
    function clearForSpotlight(): var {
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
    Prompt {
        focusedScreen: root.focused()?.modelData ?? null

        onOpened: {
            root.closeSpotlights();
            for (const notch of notches.instances)
                notch.expanded = false;
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

            root.closeSpotlights();
            if (notch.expanded)
                notch.expanded = false;
            else
                notch.open("home");
        }

        function open(panel: string): void {
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
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggleSpotlight();
        }
    }
}
