import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.theme
import qs.services
import qs.util
import qs.widgets

// The bar for one pipewire node — an output, an input, or one application's
// share of the output — with the glyph for what it sets riding in the fill
// and the figure beside it. Drag or scroll the bar to set it; click the
// glyph to mute.
//
// A muted node draws an empty track, and the figure agrees with it, rather
// than showing whatever it will go back to when it is unmuted.
RowLayout {
    id: root

    property PwNode node: null
    // a microphone rather than a speaker
    property bool input: false
    // the figure at the right; the home panel has no room for it
    property bool figure: true

    readonly property real volume: root.node?.audio?.volume ?? 0
    readonly property bool muted: root.node?.audio?.muted ?? false

    spacing: Theme.rowSpacing

    Slider {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        icon: {
            if (root.input)
                return root.muted ? Icons.microphoneMuted : Icons.microphone;
            return Icons.volume(root.volume, root.muted);
        }
        value: root.muted ? 0 : root.volume

        onMoved: fraction => Audio.setVolume(root.node, fraction)
        onIconClicked: Audio.toggleMute(root.node)
    }

    Num {
        Layout.preferredWidth: Theme.figureWidth
        Layout.alignment: Qt.AlignVCenter

        visible: root.figure

        text: root.muted ? "Muted" : Fmt.percent(root.volume)
        color: root.muted ? Theme.textDim : Theme.textMuted

        horizontalAlignment: Text.AlignRight
    }
}
