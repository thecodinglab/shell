pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.util

// Total cpu usage, sampled from /proc/stat.
//
// The resources panel draws the last `history.size` samples as a graph, so
// this ticks fast enough for that to say something: forty samples two seconds
// apart is a little over a minute of history.
Singleton {
    id: root

    // 0..1
    readonly property real usage: internal.usage
    readonly property alias history: ring.values
    readonly property int threads: internal.threads

    readonly property int interval: 2000
    // how far back the history reaches, for the graph to label itself with
    readonly property int historySeconds: Math.round(ring.size * root.interval / 1000)

    Ring {
        id: ring
    }

    QtObject {
        id: internal

        property real usage: 0
        property int threads: 0
        property real previousIdle: -1
        property real previousTotal: -1
    }

    function sample(stat: string): void {
        const lines = stat.split("\n");
        // one "cpuN" line per thread, below the "cpu" aggregate
        internal.threads = lines.filter(l => /^cpu[0-9]/.test(l)).length;

        const fields = lines[0].trim().split(/\s+/).slice(1).map(Number);
        if (fields.length < 5)
            return;

        // iowait counts as idle; a machine waiting on a disk is not busy
        const idle = fields[3] + fields[4];
        const total = fields.reduce((a, b) => a + b, 0);

        if (internal.previousTotal >= 0) {
            const deltaIdle = idle - internal.previousIdle;
            const deltaTotal = total - internal.previousTotal;

            if (deltaTotal > 0) {
                internal.usage = 1 - deltaIdle / deltaTotal;
                ring.push(internal.usage);
            }
        }

        internal.previousIdle = idle;
        internal.previousTotal = total;
    }

    FileView {
        id: file

        path: "/proc/stat"
        onLoaded: root.sample(file.text())
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: file.reload()
    }

    // The first sample only establishes the baseline. Take a second one right
    // after it so the notch opens on a real number instead of 0%.
    Timer {
        interval: 100
        running: true
        onTriggered: file.reload()
    }
}
