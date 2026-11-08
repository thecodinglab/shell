pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.util

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

    // what the bluetooth mark on the home page draws its icon from
    readonly property BluetoothDevice primary: root.devices.find(d => d.connected) ?? null

    // ── what a device is in the middle of ─────────────────────────────────
    //
    // A connection is mostly made from outside the shell — `bluetoothctl
    // connect`, a headset switched on, a keyboard waking up — so the shell
    // hears about it the way it hears about the volume: bluez says a
    // device's state has moved. The last device to move is `heard`, and
    // `moved` goes out every time one does, for the notch to announce it.

    // the device whose connection moved last
    property BluetoothDevice heard: null
    // It was being connected and went straight back to disconnected: the
    // device never answered, or turned it down.
    property bool failed: false

    signal moved

    // Bluez hands every device over with its state as the shell connects to
    // it, which would otherwise announce every one of them at start.
    property bool settled: false

    Timer {
        interval: 2000
        running: true

        onTriggered: root.settled = true
    }

    // One watcher per device, kept for as long as bluez knows it.
    Variants {
        model: Bluetooth.devices.values

        QtObject {
            id: watcher

            required property BluetoothDevice modelData

            readonly property int state: watcher.modelData.state
            readonly property bool pairing: watcher.modelData.pairing
            // what it was before the move being heard, to tell a connection
            // that failed from one that was hung up on. Set rather than
            // bound, or it would follow the state before the move was heard.
            property int was: BluetoothDeviceState.Disconnected

            Component.onCompleted: watcher.was = watcher.state
            onStateChanged: {
                root.hear(watcher.modelData, watcher.was === BluetoothDeviceState.Connecting && watcher.state === BluetoothDeviceState.Disconnected);
                watcher.was = watcher.state;
            }
            onPairingChanged: root.hear(watcher.modelData, false)
        }
    }

    function hear(device: BluetoothDevice, failed: bool): void {
        if (!root.settled)
            return;

        root.heard = device;
        root.failed = failed;
        root.moved();
    }

    // What the announcement says under a device's name: what is happening
    // to it, or what came of it.
    function news(device: BluetoothDevice, failed: bool): string {
        if (!device)
            return "";
        if (root.busy(device) || device.connected)
            return root.status(device);

        return failed ? "Couldn't connect" : "Disconnected";
    }

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

    // The line under a device's name: what is happening to it, or failing
    // that what it is. Every paired row connects when it is clicked, so that
    // is not worth saying on each of them.
    function status(device: BluetoothDevice): string {
        if (!device)
            return "";

        if (device.pairing)
            return "Pairing…";
        if (device.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
        if (device.connected)
            return ["Connected", root.battery(device)].filter(part => part).join(" · ");

        return device.paired ? root.kind(device) : "Not paired";
    }

    // How full a device says it is, or nothing if it does not say.
    function battery(device: BluetoothDevice): string {
        return device?.batteryAvailable ? Fmt.percent(device.battery) : "";
    }

    // The devices whose name or address contains `query`, in the order they
    // were already in. An empty query is not a filter.
    function search(query: string): var {
        const needle = (query ?? "").trim().toLowerCase();
        if (needle.length === 0)
            return root.devices;

        return root.devices.filter(device => root.label(device).toLowerCase().includes(needle) || (device.address ?? "").toLowerCase().includes(needle));
    }

    // The one device `query` names, for the command line: its address, its
    // name exactly, or failing those the only name it is part of — all
    // without regard to case. Null if it names none, or more than one.
    function find(query: string): BluetoothDevice {
        const needle = (query ?? "").trim().toLowerCase();
        if (needle.length === 0)
            return null;

        const exact = root.devices.find(device => (device.address ?? "").toLowerCase() === needle || root.label(device).toLowerCase() === needle);
        if (exact)
            return exact;

        const partial = root.devices.filter(device => root.label(device).toLowerCase().includes(needle));
        return partial.length === 1 ? partial[0] : null;
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
