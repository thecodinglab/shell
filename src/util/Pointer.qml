pragma Singleton

import QtQuick
import Quickshell

// How many widgets are currently holding the pointer.
//
// The notch folds up when the pointer leaves it, which would otherwise happen
// mid-drag the moment a volume slider is dragged past the edge of the slab.
// Anything that keeps following the pointer after it has left says so here.
Singleton {
    id: root

    property int drags: 0

    readonly property bool dragging: root.drags > 0

    function begin(): void {
        root.drags += 1;
    }

    function end(): void {
        root.drags = Math.max(0, root.drags - 1);
    }
}
