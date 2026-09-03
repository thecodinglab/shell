pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.theme
import qs.services
import qs.util
import qs.widgets

// Where the sound goes and where it comes from.
//
// Two modules, one each way. Each has its bar at the top and the devices it
// could be going through underneath; one tap on a device makes it the
// default, and pipewire moves the streams that follow the default across on
// its own.
ColumnLayout {
    id: root

    required property var notch

    spacing: Theme.expandedSpacing

    PanelHeader {
        Layout.fillWidth: true

        title: "Sound"

        onBack: root.notch.panel = "home"
    }

    // ── output ────────────────────────────────────────────────────────────

    Card {
        Layout.fillWidth: true

        ColumnLayout {
            spacing: Theme.px(8)

            Caption {
                Layout.bottomMargin: Theme.px(2)

                text: "Output"
            }

            RowLayout {
                Layout.fillWidth: true

                spacing: Theme.rowSpacing

                Slider {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    icon: Icons.volume(Audio.volume, Audio.muted)
                    value: Audio.muted ? 0 : Audio.volume

                    onMoved: fraction => Audio.setVolume(Audio.sink, fraction)
                    onIconClicked: Audio.toggleMute(Audio.sink)
                }

                Num {
                    Layout.preferredWidth: Theme.figureWidth
                    Layout.alignment: Qt.AlignVCenter

                    // a muted device draws an empty track, and the figure
                    // beside it has to agree with that
                    text: Audio.muted ? "Muted" : Fmt.percent(Audio.volume)
                    color: Audio.muted ? Theme.textDim : Theme.textMuted

                    horizontalAlignment: Text.AlignRight
                }
            }

            DeviceList {
                nodes: Audio.sinks
                current: Audio.sink

                onPicked: node => Audio.setDefaultSink(node)
            }
        }
    }

    // ── input, with what it is actually hearing ───────────────────────────

    Card {
        Layout.fillWidth: true

        visible: Audio.source !== null

        ColumnLayout {
            spacing: Theme.px(8)

            Caption {
                Layout.bottomMargin: Theme.px(2)

                text: "Input"
            }

            RowLayout {
                Layout.fillWidth: true

                spacing: Theme.rowSpacing

                Slider {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    icon: Audio.inputMuted ? Icons.microphoneMuted : Icons.microphone
                    value: Audio.inputMuted ? 0 : Audio.inputVolume

                    onMoved: fraction => Audio.setVolume(Audio.source, fraction)
                    onIconClicked: Audio.toggleMute(Audio.source)
                }

                Num {
                    Layout.preferredWidth: Theme.figureWidth
                    Layout.alignment: Qt.AlignVCenter

                    text: Audio.inputMuted ? "Muted" : Fmt.percent(Audio.inputVolume)
                    color: Audio.inputMuted ? Theme.textDim : Theme.textMuted

                    horizontalAlignment: Text.AlignRight
                }
            }

            // the last second or so of what the microphone picked up, which
            // is the only honest way to show a level
            Graph {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.px(2)
                Layout.rightMargin: Theme.figureWidth + Theme.rowSpacing + Theme.px(2)

                values: peaks.values
                slots: 24
                recent: 0
                implicitHeight: Theme.px(10)

                pastColor: Audio.inputMuted ? Theme.track : Theme.alpha(Theme.text, 0.4)
            }

            DeviceList {
                nodes: Audio.sources
                current: Audio.source

                onPicked: node => Audio.setDefaultSource(node)
            }
        }
    }

    Ring {
        id: peaks

        size: 24
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

    // The devices a bar could be going through, with a check beside the one
    // it is. The rows reach out past the module's content edge so their
    // hover ground wraps the name rather than starting at it.
    component DeviceList: ColumnLayout {
        id: list

        required property var nodes
        required property PwNode current

        signal picked(PwNode node)

        Layout.fillWidth: true
        Layout.leftMargin: -Theme.rowPadding
        Layout.rightMargin: -Theme.rowPadding
        Layout.topMargin: Theme.px(2)
        Layout.bottomMargin: -Theme.px(4)

        spacing: Theme.listSpacing

        Repeater {
            model: list.nodes

            ListRow {
                id: row

                required property var modelData

                readonly property bool selected: row.modelData === list.current

                Layout.fillWidth: true

                flat: true

                onClicked: list.picked(row.modelData)

                Sans {
                    Layout.fillWidth: true

                    text: Audio.label(row.modelData)
                    color: row.selected ? Theme.text : Theme.textBody
                }

                Caption {
                    text: Audio.bus(row.modelData)
                    color: Theme.textFaint
                }

                Glyph {
                    visible: row.selected

                    text: Icons.check
                    color: Theme.accent

                    font.pixelSize: Theme.fontSmall
                }
            }
        }
    }
}
