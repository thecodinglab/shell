pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// State of Config.networkInterface, mirroring waybar's three cases:
// no carrier is "disconnected", carrier without an address is "linked",
// anything else is "connected" and carries an address.
Singleton {
    id: root

    property string state: "disconnected"
    property string address: ""

    function refresh(): void {
        // a refresh while one is in flight would lose the newer state
        if (!query.running)
            query.running = true;
    }

    function parse(json: string): void {
        let links = [];
        try {
            links = JSON.parse(json);
        } catch (e) {
            links = [];
        }

        const link = links[0];
        if (!link || link.operstate !== "UP") {
            root.state = "disconnected";
            root.address = "";
            return;
        }

        const addresses = link.addr_info ?? [];
        // waybar prefers ipv4 and falls back to ipv6
        const address = addresses.find(a => a.family === "inet") ?? addresses.find(a => a.family === "inet6");

        root.state = address ? "connected" : "linked";
        root.address = address?.local ?? "";
    }

    Process {
        id: query

        command: ["ip", "-json", "address", "show", "dev", Config.networkInterface]

        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }

        onExited: exitCode => {
            // the interface is gone (or was never there)
            if (exitCode !== 0) {
                root.state = "disconnected";
                root.address = "";
            }
        }
    }

    // netlink events, so the bar reacts as instantly as waybar's own netlink
    // socket did instead of waiting for the next poll
    Process {
        running: true
        command: ["ip", "monitor", "link", "address", "dev", Config.networkInterface]

        stdout: SplitParser {
            onRead: root.refresh()
        }
    }

    Timer {
        // safety net in case an event is missed while `ip monitor` restarts
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
