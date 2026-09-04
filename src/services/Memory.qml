pragma Singleton

import QtQuick
import Quickshell.Io

// Memory pressure, from /proc/meminfo.
//
// "Used" is total minus available rather than total minus free: the page
// cache is free for the taking, and counting it as used makes every idle
// machine look full.
Sampler {
    id: root

    property real availableBytes: 0
    property real totalBytes: 0

    readonly property real usedBytes: Math.max(0, root.totalBytes - root.availableBytes)

    onPoll: file.reload()

    function parse(meminfo: string): void {
        // one "Name:   12345 kB" line per figure
        const field = name => Number(meminfo.match(new RegExp(`^${name}:\\s+(\\d+)`, "m"))?.[1] ?? 0) * 1024;

        root.totalBytes = field("MemTotal");
        root.availableBytes = field("MemAvailable");
        root.record(root.totalBytes > 0 ? root.usedBytes / root.totalBytes : 0);
    }

    FileView {
        id: file

        path: "/proc/meminfo"
        onLoaded: root.parse(file.text())
    }
}
