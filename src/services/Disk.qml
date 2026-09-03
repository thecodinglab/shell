pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Free space on Config.diskPath in bytes, on waybar's 30s cadence.
//
// `stat -f` hands back exactly the two statvfs fields waybar multiplied:
// blocks available to unprivileged users, and the fragment size.
Singleton {
    id: root

    property real freeBytes: 0

    Process {
        id: proc

        command: ["stat", "-f", "-c", "%a %S", Config.diskPath]

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = this.text.trim().split(/\s+/).map(Number);
                if (fields.length === 2 && fields.every(f => !isNaN(f)))
                    root.freeBytes = fields[0] * fields[1];
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
