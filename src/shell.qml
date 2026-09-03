pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.notch

ShellRoot {
    Variants {
        id: notches

        model: Quickshell.screens

        Notch {}
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

        function focused(): var {
            const notch = notches.instances.find(n => Hyprland.monitorFor(n.modelData) === Hyprland.focusedMonitor);
            return notch ?? notches.instances[0] ?? null;
        }

        function toggle(): void {
            const notch = focused();
            if (!notch)
                return;

            if (notch.expanded)
                notch.expanded = false;
            else
                notch.open("home");
        }

        function open(panel: string): void {
            focused()?.open(panel);
        }

        function close(): void {
            for (const notch of notches.instances)
                notch.expanded = false;
        }

        function peek(): void {
            focused()?.peek();
        }
    }
}
