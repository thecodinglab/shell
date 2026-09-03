pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Total cpu usage in percent, sampled from /proc/stat on waybar's 10s cadence.
Singleton {
    id: root

    readonly property int usage: internal.usage

    QtObject {
        id: internal

        property int usage: 0
        property real previousIdle: -1
        property real previousTotal: -1
    }

    function sample(stat: string): void {
        // the first line is the "cpu" aggregate over all cores
        const fields = stat.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (fields.length < 5)
            return;

        // waybar counts iowait as idle
        const idle = fields[3] + fields[4];
        const total = fields.reduce((a, b) => a + b, 0);

        if (internal.previousTotal >= 0) {
            const deltaIdle = idle - internal.previousIdle;
            const deltaTotal = total - internal.previousTotal;

            if (deltaTotal > 0)
                // truncated, not rounded, like waybar's cast to uint16
                internal.usage = Math.trunc(100 * (1 - deltaIdle / deltaTotal));
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
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: file.reload()
    }

    // waybar seeds its baseline and takes a second sample 100ms later so the
    // bar shows a real number immediately instead of 0% for the first tick
    Timer {
        interval: 100
        running: true
        onTriggered: file.reload()
    }
}
