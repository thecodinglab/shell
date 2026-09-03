pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.util

// Memory pressure, from /proc/meminfo.
//
// "Used" is total minus available rather than total minus free: the page
// cache is free for the taking, and counting it as used makes every idle
// machine look full.
Singleton {
    id: root

    property real availableKb: 0
    property real totalKb: 0

    readonly property real usedKb: Math.max(0, root.totalKb - root.availableKb)
    readonly property real usage: root.totalKb > 0 ? root.usedKb / root.totalKb : 0
    readonly property alias history: ring.values

    readonly property int interval: 5000
    // how far back the history reaches, for the graph to label itself with
    readonly property int historySeconds: Math.round(ring.size * root.interval / 1000)

    Ring {
        id: ring
    }

    function parse(meminfo: string): void {
        for (const line of meminfo.split("\n")) {
            if (line.startsWith("MemAvailable:"))
                root.availableKb = Number(line.split(/\s+/)[1]);
            else if (line.startsWith("MemTotal:"))
                root.totalKb = Number(line.split(/\s+/)[1]);
        }

        ring.push(root.usage);
    }

    FileView {
        id: file

        path: "/proc/meminfo"
        onLoaded: root.parse(file.text())
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: file.reload()
    }
}
