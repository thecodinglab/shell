pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluez, in the shape the panel wants it.
//
// Named `Bt` rather than `Bluetooth` so it does not collide with the
// singleton of that name this file is built on.
Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.adapter?.enabled ?? false
    readonly property bool discovering: root.adapter?.discovering ?? false

    // Paired devices first, connected ones above those, and unpaired ones
    // last so a scan cannot push what you own off the bottom of the list.
    readonly property var devices: [...Bluetooth.devices.values].sort((a, b) => {
        if (a.connected !== b.connected)
            return a.connected ? -1 : 1;
        if (a.paired !== b.paired)
            return a.paired ? -1 : 1;
        return root.label(a).localeCompare(root.label(b));
    })

    readonly property var connected: root.devices.filter(d => d.connected)
    // what the collapsed tile shows, and what the icon is drawn from
    readonly property BluetoothDevice primary: root.connected[0] ?? null

    function label(device: BluetoothDevice): string {
        return device?.name || device?.deviceName || device?.address || "unknown device";
    }

    // What a device is, in a word, from the freedesktop icon name bluez
    // hands out for it.
    function kind(device: BluetoothDevice): string {
        switch (device?.icon ?? "") {
        case "audio-headset":
            return "Headset";
        case "audio-headphones":
            return "Headphones";
        case "audio-card":
        case "audio-speakers":
            return "Speaker";
        case "input-keyboard":
            return "Keyboard";
        case "input-mouse":
            return "Mouse";
        case "input-tablet":
            return "Trackpad";
        case "input-gaming":
            return "Controller";
        case "phone":
            return "Phone";
        case "computer":
            return "Computer";
        case "video-display":
            return "Display";
        default:
            return "Device";
        }
    }

    function toggle(): void {
        if (root.adapter)
            root.adapter.enabled = !root.adapter.enabled;
    }

    // Everything bluez is still thinking about: a connection being made or
    // dropped, or a pairing waiting on the device to agree. Nothing useful can
    // be asked of a device in this state, so the row it is on says so and
    // stops taking taps.
    function busy(device: BluetoothDevice): bool {
        if (!device)
            return false;

        return device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting;
    }

    // What the tag at the end of a row says: what is happening, or failing
    // that, what a tap would do.
    function status(device: BluetoothDevice): string {
        if (!device)
            return "";

        if (device.pairing)
            return "pairing";
        if (device.state === BluetoothDeviceState.Connecting)
            return "connecting";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "disconnecting";
        if (device.connected)
            return "connected";

        return device.paired ? "connect" : "pair";
    }

    // The devices whose name or address contains `query`, in the order they
    // were already in. An empty query is not a filter.
    function search(query: string): var {
        const needle = (query ?? "").trim().toLowerCase();
        if (needle.length === 0)
            return root.devices;

        return root.devices.filter(device => root.label(device).toLowerCase().includes(needle) || (device.address ?? "").toLowerCase().includes(needle));
    }

    // One gesture for the whole lifecycle: pair what is new, connect what is
    // known, hang up on what is already talking.
    function activate(device: BluetoothDevice): void {
        if (!device || root.busy(device))
            return;

        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else
            device.pair();
    }
}
