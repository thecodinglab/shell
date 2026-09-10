pragma Singleton

import QtQuick
import Quickshell

// Whether the last thing the user did was press a key.
//
// The focus ring is drawn only then: a control that was clicked has focus
// too, but drawing a ring around it would be telling the pointer where the
// pointer is. Any control that takes a key says so here, and any movement of
// the pointer takes it back.
Singleton {
    id: root

    property bool keyboard: false

    function key(): void {
        root.keyboard = true;
    }

    function pointer(): void {
        root.keyboard = false;
    }
}
