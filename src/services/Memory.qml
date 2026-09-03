pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Available memory in kibibytes, from /proc/meminfo on waybar's 30s cadence.
Singleton {
    id: root

    property real availableKb: 0

    function parse(meminfo: string): void {
        for (const line of meminfo.split("\n")) {
            if (line.startsWith("MemAvailable:")) {
                root.availableKb = Number(line.split(/\s+/)[1]);
                return;
            }
        }
    }

    FileView {
        id: file

        path: "/proc/meminfo"
        onLoaded: root.parse(file.text())
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: file.reload()
    }
}
