import QtQuick
import Quickshell
import qs.util

// A reading taken on a timer, and the recent history of it the graphs draw.
//
// What is read, and how, belongs to whatever is built on this: the timer
// says when to `poll`, and each reading comes back through `record`. The
// resources panel draws the last `history.size` of them, so the interval is
// also how much time a graph covers.
Singleton {
    id: root

    property int interval: 5000
    // 0..1, the last reading
    property real usage: 0
    readonly property alias history: ring.values
    // how far back the history reaches, for the graph to label itself with
    readonly property int historySeconds: Math.round(ring.size * root.interval / 1000)

    // time for another reading
    signal poll

    function record(value: real): void {
        root.usage = value;
        ring.push(value);
    }

    Ring {
        id: ring
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: root.poll()
    }
}
