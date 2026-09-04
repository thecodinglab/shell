pragma Singleton

import QtQuick
import Quickshell.Io

// Total cpu usage, sampled from /proc/stat.
//
// Quick enough for the graph to say something: forty samples two seconds
// apart is a little over a minute of history.
Sampler {
    id: root

    property int threads: 0

    property real previousIdle: -1
    property real previousTotal: -1

    interval: 2000

    onPoll: file.reload()

    function sample(stat: string): void {
        const lines = stat.split("\n");
        // one "cpuN" line per thread, below the "cpu" aggregate
        root.threads = lines.filter(l => /^cpu[0-9]/.test(l)).length;

        const fields = lines[0].trim().split(/\s+/).slice(1).map(Number);
        if (fields.length < 5)
            return;

        // iowait counts as idle; a machine waiting on a disk is not busy
        const idle = fields[3] + fields[4];
        const total = fields.reduce((a, b) => a + b, 0);

        const deltaTotal = total - root.previousTotal;
        if (root.previousTotal >= 0 && deltaTotal > 0)
            root.record(1 - (idle - root.previousIdle) / deltaTotal);

        root.previousIdle = idle;
        root.previousTotal = total;
    }

    FileView {
        id: file

        path: "/proc/stat"
        onLoaded: root.sample(file.text())
    }

    // The first sample only establishes the baseline. Take a second one right
    // after it so the notch opens on a real number instead of 0%.
    Timer {
        interval: 100
        running: true
        onTriggered: file.reload()
    }
}
