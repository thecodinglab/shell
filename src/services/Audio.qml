pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.config

// Pipewire, narrowed to the questions the notch asks: what is playing sound,
// where it is going, and how loud each application playing into it is.
//
// A playback stream is a sink as far as pipewire is concerned — it is
// somewhere audio goes — so `isStream` is the only thing telling an
// application apart from a device, and both are listed here.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    // What is playing right now, one node per application. Recording streams
    // are left out: a bar per microphone user is a setting nobody reaches
    // for, and the panel already says what the microphone is hearing.
    readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isSink && n.isStream)

    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false

    // The output's volume or mute has been set, by whoever set it: a media
    // key, the notch's own slider, another application. It is the sink's
    // own change signals rather than `volume` above changing, so that the
    // default output switching to a device that happens to be at a different
    // level does not count as anyone having turned it.
    signal adjusted

    Connections {
        target: root.sink?.audio ?? null

        function onVolumesChanged(): void {
            root.adjusted();
        }

        function onMutedChanged(): void {
            root.adjusted();
        }
    }

    // A node's own name is a pipewire object path more often than not, so
    // prefer whatever it says it would like to be called.
    function label(node: PwNode): string {
        return node?.description || node?.nickname || node?.name || "";
    }

    // The application behind a stream. A stream carries no description and no
    // nickname, so `label` would fall through to a node name that is whatever
    // the client happened to register itself as; what the application calls
    // itself is closer to what it is called on screen. Capitalised, because
    // half of them introduce themselves in lower case.
    function app(node: PwNode): string {
        const name = node?.properties?.["application.name"] || node?.name || "";
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    // The bus a node hangs off, which is the only thing distinguishing two
    // otherwise identically named sinks.
    function bus(node: PwNode): string {
        const props = node?.properties ?? ({});
        return props["device.api"] === "bluez5" ? "bluetooth" : (props["api.alsa.path"] || props["device.api"] || "");
    }

    function setVolume(node: PwNode, value: real): void {
        if (!node?.audio)
            return;

        const volume = Math.max(0, Math.min(1, value));
        node.audio.volume = volume;

        const player = root.player(node);
        if (player)
            player.volume = volume;
    }

    // The mpris player behind a stream, for the applications in
    // `Config.mprisVolumeApps` that take their volume from their own slider
    // rather than from the stream — see there. Pipewire knows the stream by
    // the application's name and mpris knows the player by its desktop entry
    // or what it calls itself, which agree once case is ignored.
    function player(node: PwNode): MprisPlayer {
        const name = (node?.properties?.["application.name"] ?? "").toLowerCase();
        if (!node?.isStream || name === "" || !Config.mprisVolumeApps.some(app => app.toLowerCase() === name))
            return null;

        return Mpris.players.values.find(p => p.canControl && p.volumeSupported && (p.desktopEntry.toLowerCase() === name || p.identity.toLowerCase() === name)) ?? null;
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
    // node, and every device and application in the audio panel shows its own.
    PwObjectTracker {
        objects: [...root.sinks, ...root.sources, ...root.streams]
    }
}
