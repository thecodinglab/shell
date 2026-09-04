pragma Singleton

import QtQuick
import Quickshell

// The ways out of the session, and the one way to keep it up.
//
// The actions go through logind and hyprland's own idle daemon rather than
// through the shell: locking asks logind to lock the session, which hypridle
// answers with hyprlock, and sleeping asks logind to suspend, which hypridle
// locks ahead of. So whatever the session is set up to do on a lid closing,
// a keybind, or a timeout, a press here does the same thing.
//
// `awake` is the inhibitor: while it is set, every notch holds a wayland
// idle inhibitor on its window — see Notch — and the idle daemon neither
// locks the screen nor turns it off. It is a request, not a lock: the
// session can still be locked or put to sleep by hand from here.
Singleton {
    id: root

    property bool awake: false

    function lock(): void {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function suspend(): void {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function poweroff(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
