import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.util
import qs.widgets

// One audio device on one line: mute it with the glyph, set it with the
// track, or follow the chevron into the audio panel to change where it goes.
RowLayout {
    id: root

    property var node: null
    property string icon: ""
    property bool muted: false
    property color fillColor: Theme.accent

    signal open

    readonly property real level: root.node?.audio?.volume ?? 0

    spacing: Theme.rowSpacing

    Glyph {
        Layout.alignment: Qt.AlignVCenter

        text: root.icon
        color: root.muted ? Theme.textDim : Theme.textBody

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Theme.px(4)

            cursorShape: Qt.PointingHandCursor
            enabled: root.node !== null

            onClicked: Audio.toggleMute(root.node)
        }
    }

    Slider {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        // a muted device reads as silent rather than as whatever it will go
        // back to when it is unmuted
        value: root.muted ? 0 : root.level
        fillColor: root.fillColor

        onMoved: fraction => Audio.setVolume(root.node, fraction)
    }

    Mono {
        Layout.preferredWidth: Theme.px(34)
        Layout.alignment: Qt.AlignVCenter

        text: Fmt.percent(root.level)
        color: Theme.textMuted

        font.pixelSize: Theme.fontMeta
        horizontalAlignment: Text.AlignRight
    }

    IconButton {
        Layout.alignment: Qt.AlignVCenter

        icon: Icons.forward
        pixelSize: Theme.fontSmall

        onClicked: root.open()
    }
}
