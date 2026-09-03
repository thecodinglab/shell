pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Which workspaces belong to which monitor, from hyprland's workspace rules
// (`workspace = 3, monitor:DP-4` and friends).
//
// A workspace bound to a monitor is that monitor's whether or not it is open
// right now, so the dots can draw it and a click on it lands there. Hyprland
// does not announce the rules over its event socket, so they are asked for
// over the request socket the way `hyprctl workspacerules` would, once at
// startup and again every time the config is reloaded.
Singleton {
    id: root

    // monitor name -> the workspace ids bound to it, ascending
    property var bound: ({})

    function idsFor(monitor: string): list<int> {
        return root.bound[monitor] ?? [];
    }

    // The ids a rule's selector covers. Rules can also select workspaces by
    // name or pick out special ones; those never show up as dots, so they
    // are dropped here.
    function ids(selector: string): list<int> {
        if (/^\d+$/.test(selector))
            return [Number(selector)];

        const range = /^r\[(\d+)-(\d+)\]$/.exec(selector);
        if (!range)
            return [];

        const out = [];
        for (let i = Number(range[1]); i <= Number(range[2]); i++)
            out.push(i);
        return out;
    }

    function parse(json: string): void {
        let rules = [];
        try {
            rules = JSON.parse(json);
        } catch (e) {
            rules = [];
        }

        const bound = {};
        for (const rule of rules) {
            if (!rule.monitor)
                continue;
            bound[rule.monitor] = (bound[rule.monitor] ?? []).concat(root.ids(rule.workspaceString));
        }
        for (const monitor in bound)
            bound[monitor] = [...new Set(bound[monitor])].sort((a, b) => a - b);

        root.bound = bound;
    }

    function refresh(): void {
        if (!query.connected)
            query.connected = true;
    }

    Socket {
        id: query

        property string buffer: ""

        path: Hyprland.requestSocketPath

        parser: SplitParser {
            splitMarker: ""
            onRead: data => query.buffer += data
        }

        // hyprland answers and hangs up, so the disconnect is the end of
        // the reply
        onConnectedChanged: {
            if (query.connected) {
                query.write("j/workspacerules");
                return;
            }

            if (query.buffer.length > 0)
                root.parse(query.buffer);
            query.buffer = "";
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name === "configreloaded")
                root.refresh();
        }
    }

    Component.onCompleted: root.refresh()
}
