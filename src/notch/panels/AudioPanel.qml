import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.theme
import qs.services
import qs.util
import qs.widgets

// Where the sound goes and where it comes from.
//
// One tap on a row makes that device the default; pipewire moves the streams
// that follow the default across on its own.
ColumnLayout {
    id: root

    required property var notch

    spacing: Theme.px(10)

    PanelHeader {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.px(4)

        title: "Audio"

        onBack: root.notch.panel = "home"

        Caption {
            text: "pipewire"
            color: Theme.textDim
        }
    }

    // ── the default sink, big enough to aim at ────────────────────────────

    Card {
        Layout.fillWidth: true

        radius: Theme.rowRadius

        RowLayout {
            spacing: Theme.rowSpacing

            Glyph {
                Layout.alignment: Qt.AlignVCenter

                text: Icons.volume(Audio.volume, Audio.muted)
                color: Audio.muted ? Theme.textDim : Theme.textBody

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Theme.px(4)

                    cursorShape: Qt.PointingHandCursor

                    onClicked: Audio.toggleMute(Audio.sink)
                }
            }

            Slider {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                value: Audio.muted ? 0 : Audio.volume
                knob: true
                trackHeight: Theme.px(8)

                onMoved: fraction => Audio.setVolume(Audio.sink, fraction)
            }

            Mono {
                Layout.preferredWidth: Theme.px(34)
                Layout.alignment: Qt.AlignVCenter

                text: Fmt.percent(Audio.volume)
                color: Theme.textMuted

                font.pixelSize: Theme.fontMeta
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    Caption {
        Layout.leftMargin: Theme.px(6)

        text: "output"
    }

    Repeater {
        model: Audio.sinks

        ListRow {
            id: sinkRow

            required property var modelData

            Layout.fillWidth: true

            active: sinkRow.modelData === Audio.sink
            padding: Theme.px(9)

            onClicked: Audio.setDefaultSink(sinkRow.modelData)

            Mono {
                Layout.preferredWidth: Theme.px(14)

                text: sinkRow.active ? Icons.selected : Icons.unselected
                color: sinkRow.active ? Theme.accent : Theme.textDim

                font.pixelSize: Theme.fontMeta
                horizontalAlignment: Text.AlignHCenter
            }

            Sans {
                Layout.fillWidth: true

                text: Audio.label(sinkRow.modelData)
                color: Theme.text
            }

            Mono {
                text: Audio.bus(sinkRow.modelData)
            }
        }
    }

    // ── the default source, with what it is actually hearing ──────────────

    Card {
        Layout.fillWidth: true
        Layout.topMargin: Theme.px(2)

        radius: Theme.rowRadius
        visible: Audio.source !== null

        RowLayout {
            spacing: Theme.rowSpacing

            Glyph {
                Layout.alignment: Qt.AlignVCenter

                text: Audio.inputMuted ? Icons.microphoneMuted : Icons.microphone
                color: Audio.inputMuted ? Theme.textDim : Theme.textBody

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Theme.px(4)

                    cursorShape: Qt.PointingHandCursor

                    onClicked: Audio.toggleMute(Audio.source)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true

                spacing: Theme.px(4)

                Sans {
                    Layout.fillWidth: true

                    text: Audio.label(Audio.source)
                    color: Theme.text
                }

                Graph {
                    Layout.fillWidth: true

                    // the last second or so of what the microphone picked up,
                    // which is the only honest way to show a level
                    values: peaks.values
                    slots: 18
                    recent: 0
                    implicitHeight: Theme.px(10)

                    pastColor: Audio.inputMuted ? Theme.track : Theme.alpha(Theme.text, 0.4)
                }
            }

            Mono {
                Layout.preferredWidth: Theme.px(34)
                Layout.alignment: Qt.AlignVCenter

                text: Fmt.percent(Audio.inputVolume)
                color: Theme.textMuted

                font.pixelSize: Theme.fontMeta
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    Ring {
        id: peaks

        size: 18
    }

    // Monitoring a node costs pipewire real work, so it only runs while this
    // panel is the one on screen.
    PwNodePeakMonitor {
        id: monitor

        node: Audio.source
        enabled: root.visible
    }

    Timer {
        interval: 60
        running: monitor.enabled
        repeat: true

        onTriggered: peaks.push(Audio.inputMuted ? 0 : monitor.peak)
    }
}
