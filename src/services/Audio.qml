pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Pipewire, narrowed to the two questions the notch asks: what is playing
// sound, and where is it going.
//
// Streams are left out. The panel routes the machine's audio, not each
// application's, so only real devices show up.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false

    readonly property real inputVolume: root.source?.audio?.volume ?? 0
    readonly property bool inputMuted: root.source?.audio?.muted ?? false

    // A node's own name is a pipewire object path more often than not, so
    // prefer whatever it says it would like to be called.
    function label(node: PwNode): string {
        return node?.description || node?.nickname || node?.name || "";
    }

    // The bus a node hangs off, which is the only thing distinguishing two
    // otherwise identically named sinks.
    function bus(node: PwNode): string {
        const props = node?.properties ?? ({});
        return props["device.api"] === "bluez5" ? "bluetooth" : (props["api.alsa.path"] || props["device.api"] || "");
    }

    function setVolume(node: PwNode, value: real): void {
        if (node?.audio)
            node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute(node: PwNode): void {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    // Asking for a default rather than setting one: pipewire picks it up on
    // the next round trip and tells us through `defaultAudioSink`.
    function setDefaultSink(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node: PwNode): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Volume and mute are only pushed to us while something is holding the
    // node, and every sink in the audio panel shows its own.
    PwObjectTracker {
        objects: [...root.sinks, ...root.sources]
    }
}
