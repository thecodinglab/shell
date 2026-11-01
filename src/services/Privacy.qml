pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Who is listening and who is watching: the microphone being recorded, the
// camera being read and the screen being shared, and by which applications
// — the dot beside the notch on a mac, read off pipewire's graph.
//
// The microphone is anyone holding an audio stream going in rather than out.
// A meter holds one too, as far as pipewire is concerned: the level under the
// input bar in the sound panel is the shell itself recording the microphone,
// a few peaks a second. A stream like that says what it is in its own
// properties — `stream.monitor`, and a `media.category` of Monitor or
// Manager, which is quickshell's own test for one — and is not counted. The
// names are no use for this: quickshell's meter registers its node under
// whatever the binary happens to be called, which on nix is the wrapper's
// name, and the process it comes from is kept on the pipewire client rather
// than on the node, where quickshell does not show it.
//
// The camera and the screen are both a video source, told apart by what is
// behind it. A camera is a device; a shared screen is a stream a program is
// offering — the portal offers each screen or window it is asked to share as
// one, for as long as the share lasts. A camera is in use while something is
// linked to it, and whoever that is, is who is using it. A shared screen is
// in use for as long as it is there at all, linked or not yet.
//
// What pipewire never sees is not here: an application reading the camera
// straight from its device file, or recording the screen through the
// compositor's own protocol rather than the portal.
Singleton {
    id: root

    // ── the microphone ────────────────────────────────────────────────────

    // Every audio stream coming in, meters included: these are what has to
    // be held to be read at all — see the tracker below.
    readonly property var inputs: Pipewire.nodes.values.filter(n => n.audio && n.isStream && !n.isSink)

    // ...and the ones that are somebody recording. Only judged once a node is
    // bound and its properties are in, or a meter would light the indicator
    // for the moment before it had said it was one.
    readonly property var recording: root.inputs.filter(n => n.ready && root.listening(n))

    // ── the camera and the screen ─────────────────────────────────────────

    readonly property var sources: Pipewire.nodes.values.filter(n => n.type === PwNodeType.VideoSource)

    // what is reading each video source, by the links from it
    readonly property var links: Pipewire.linkGroups.values.filter(g => root.sources.includes(g.source))
    readonly property var readers: root.unique(root.links.map(g => g.target))

    readonly property var cameras: root.sources.filter(n => n.ready && root.device(n))
    readonly property var screens: root.sources.filter(n => n.ready && !root.device(n))

    readonly property var filming: root.unique(root.links.filter(g => root.cameras.includes(g.source)).map(g => g.target))
    readonly property var watching: root.unique(root.links.filter(g => root.screens.includes(g.source)).map(g => g.target))

    // ── what is in use, and by whom ───────────────────────────────────────

    readonly property bool microphone: root.recording.length > 0
    readonly property bool camera: root.filming.length > 0
    readonly property bool screen: root.screens.length > 0
    readonly property bool active: root.microphone || root.camera || root.screen

    // the applications, each once, however many streams it has open
    readonly property var microphoneApps: root.apps(root.recording)
    readonly property var cameraApps: root.apps(root.filming)
    readonly property var screenApps: root.apps(root.watching)

    // All of it in a sentence, for whatever reads the indicator out.
    readonly property string summary: [root.microphone ? root.said("Microphone in use", "by", root.microphoneApps) : "", root.camera ? root.said("Camera in use", "by", root.cameraApps) : "", root.screen ? root.said("Screen shared", "with", root.screenApps) : ""].filter(part => part).join("; ")

    // A capture stream that is recording a source, rather than metering one
    // or recording what is playing: a stream on a sink's monitor is taking the
    // sound going out, which is not the microphone.
    function listening(node: PwNode): bool {
        const props = node.properties;
        if (String(props["stream.monitor"]) === "true" || String(props["stream.capture.sink"]) === "true")
            return false;
        return props["media.category"] !== "Monitor" && props["media.category"] !== "Manager";
    }

    // A video source with a device behind it — v4l2, libcamera — rather than
    // one a program is offering.
    function device(node: PwNode): bool {
        const props = node.properties;
        return props["device.id"] !== undefined || props["device.api"] !== undefined;
    }

    function apps(nodes: var): var {
        return root.unique(nodes.map(n => root.app(n)).filter(name => name));
    }

    // The application behind a stream, named the way the sound panel names
    // it — see `Audio.app` — less the disguise nix puts on a wrapped binary.
    // A native stream that says nothing else about itself is named after its
    // process, and under nix that is `.firefox-wrapped`.
    function app(node: PwNode): string {
        const name = (node?.properties?.["application.name"] || node?.name || "").replace(/^\.(.+)-wrapped$/, "$1");
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    function unique(list: var): var {
        return list.filter((item, i) => item && list.indexOf(item) === i);
    }

    function said(what: string, by: string, apps: var): string {
        return apps.length > 0 ? `${what} ${by} ${apps.join(", ")}` : what;
    }

    // A node's properties are only sent while something holds it, and they
    // are the whole of what tells a meter from a recording and a camera from
    // a screen. Held whether or not they turn out to count, so that judging
    // one never lets go of it.
    PwObjectTracker {
        objects: [...root.inputs, ...root.sources, ...root.readers]
    }
}
