import QtQuick
import Quickshell.Services.Pipewire
import qs.widgets

ModuleText {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink

    text: root.sink?.audio?.muted ? "󰝟 " : `󰕾   ${Math.round((root.sink?.audio?.volume ?? 0) * 100)}%`

    // properties of a node are only tracked while something holds on to it
    PwObjectTracker {
        objects: [root.sink]
    }

    MouseArea {
        anchors.fill: parent

        // waybar changed the volume by one percentage point per scroll tick,
        // never past 100%
        onWheel: wheel => {
            const audio = root.sink?.audio;
            if (!audio)
                return;

            const step = wheel.angleDelta.y > 0 ? 0.01 : -0.01;
            audio.volume = Math.max(0, Math.min(1, audio.volume + step));
        }
    }
}
