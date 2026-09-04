pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Every link the machine is on, from `ip`.
//
// Each one is in one of waybar's three states: no carrier is "disconnected",
// a carrier without an address is "linked", and anything else is "connected"
// and carries an address. Where waybar only ever spoke for one interface, the
// notch lists all of them, so a machine on ethernet and a tunnel at once says
// so instead of picking one and hiding the other.
Singleton {
    id: root

    // The interfaces that are up, the ones carrying an address first and the
    // configured one ahead of its equals. Interfaces that are down are not in
    // here at all: a link with no carrier is not a connection, and the panel
    // says "offline" rather than listing what is not working.
    property var interfaces: []

    // What the rest of the shell means when it says "the network".
    readonly property var primary: root.interfaces[0] ?? null
    readonly property string state: root.primary?.state ?? "disconnected"
    readonly property string address: root.primary?.address ?? ""

    function refresh(): void {
        // a refresh while one is in flight would lose the newer state
        if (!query.running)
            query.running = true;
    }

    // Which kind of link a name is. Read off the name rather than asked of the
    // kernel because the only thing it decides is which glyph the row gets,
    // and the naming is predictable enough for that.
    function kind(name: string): string {
        if (/^wl/.test(name))
            return "wireless";
        if (/^(wg|tun|tap|ppp|tailscale|zt)/.test(name))
            return "tunnel";
        return "wired";
    }

    // ...and what that kind is called on the panel.
    function kindLabel(kind: string): string {
        switch (kind) {
        case "wireless":
            return "Wi‑Fi";
        case "tunnel":
            return "VPN";
        default:
            return "Ethernet";
        }
    }

    // Bridges, container veths and the like: real interfaces, but not ways out
    // of the machine, so they are not connections as far as the notch is
    // concerned.
    function ignored(name: string): bool {
        return Config.networkIgnore.some(prefix => name.startsWith(prefix));
    }

    function parse(json: string): void {
        let links = [];
        try {
            links = JSON.parse(json);
        } catch (e) {
            links = [];
        }

        const found = [];
        for (const link of links) {
            const name = link.ifname ?? "";
            // loopback is not a connection to anything
            if (!name || link.link_type === "loopback" || root.ignored(name))
                continue;

            const addresses = link.addr_info ?? [];
            // waybar prefers ipv4 and falls back to ipv6; a link-local v6
            // address is not an address anyone can be reached on
            const address = addresses.find(a => a.family === "inet") ?? addresses.find(a => a.family === "inet6" && a.scope === "global");

            // A tunnel never leaves UNKNOWN however up it is, so an address is
            // what says it is carrying something. The same test throws out the
            // ports a bridge or an overlay leaves lying around, which are
            // UNKNOWN too and have nothing but a link-local address.
            if (link.operstate !== "UP" && !(link.operstate === "UNKNOWN" && address))
                continue;

            found.push({
                name: name,
                kind: root.kind(name),
                state: address ? "connected" : "linked",
                address: address?.local ?? ""
            });
        }

        found.sort((a, b) => {
            if (a.state !== b.state)
                return a.state === "connected" ? -1 : 1;

            // the configured interface is the one the machine is meant to be
            // on, so it leads the ones it is tied with
            const preferred = name => name === Config.networkInterface ? 0 : 1;
            if (preferred(a.name) !== preferred(b.name))
                return preferred(a.name) - preferred(b.name);

            return a.name.localeCompare(b.name);
        });

        root.interfaces = found;
    }

    Process {
        id: query

        command: ["ip", "-json", "address", "show"]

        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }

        onExited: exitCode => {
            // `ip` is not there, or had nothing to say
            if (exitCode !== 0)
                root.interfaces = [];
        }
    }

    // netlink events, so the notch reacts as instantly as waybar's own netlink
    // socket did instead of waiting for the next poll
    Process {
        running: true
        command: ["ip", "monitor", "link", "address"]

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
