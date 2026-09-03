pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.util

// Space on Config.diskPath.
//
// `stat -f` hands back the statvfs fields directly: blocks available to
// unprivileged users, total blocks, and the size of one. Free and total are
// measured against different block counts on purpose — the root reserve is
// space this user cannot have, so it belongs in neither.
Singleton {
    id: root

    property real freeBytes: 0
    property real totalBytes: 0

    readonly property real usage: root.totalBytes > 0 ? 1 - root.freeBytes / root.totalBytes : 0
    readonly property alias history: ring.values

    readonly property int interval: 30000
    // how far back the history reaches, for the graph to label itself with
    readonly property int historySeconds: Math.round(ring.size * root.interval / 1000)

    Ring {
        id: ring
    }

    Process {
        id: proc

        command: ["stat", "-f", "-c", "%a %b %S", Config.diskPath]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = this.text.trim().split(/\s+/).map(Number);
                if (fields.length !== 3 || fields.some(f => isNaN(f)))
                    return;

                const [available, total, blockSize] = fields;
                root.freeBytes = available * blockSize;
                root.totalBytes = total * blockSize;
                ring.push(root.usage);
            }
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
