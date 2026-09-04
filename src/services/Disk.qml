pragma Singleton

import QtQuick
import Quickshell.Io
import qs.config

// Space on Config.diskPath.
//
// `stat -f` hands back the statvfs fields directly: blocks available to
// unprivileged users, total blocks, and the size of one. Free and total are
// measured against different block counts on purpose — the root reserve is
// space this user cannot have, so it belongs in neither.
Sampler {
    id: root

    property real freeBytes: 0
    property real totalBytes: 0

    interval: 30000

    onPoll: proc.running = true

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
                root.record(total > 0 ? 1 - available / total : 0);
            }
        }
    }
}
