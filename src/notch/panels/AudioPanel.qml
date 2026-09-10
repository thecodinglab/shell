pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.theme
import qs.services
import qs.widgets
import qs.notch

// Where the sound goes and where it comes from.
//
// A section each way. Each has its bar at the top and the devices it could
// be going through underneath; one tap on a device makes it the default, and
// pipewire moves the streams that follow the default across on its own.
//
// Between them, a bar for each application that is playing, which is the same
// control one level down: the output bar sets what the machine is doing, and
// these set each application's share of it.
ColumnLayout {
    id: root

    required property var notch

    readonly property bool inputMuted: Audio.source?.audio?.muted ?? false

    spacing: Theme.sectionSpacing

    PanelHeader {
        Layout.fillWidth: true

        notch: root.notch
        title: "Sound"
    }

    // ── output ────────────────────────────────────────────────────────────

    ColumnLayout {
        Layout.fillWidth: true

        spacing: Theme.stackSpacing

        Heading {
            text: "Output"
        }

        Volume {
            Layout.fillWidth: true

            node: Audio.sink
            label: "Output volume"
        }

        DeviceList {
            nodes: Audio.sinks
            current: Audio.sink

            onPicked: node => Audio.setDefaultSink(node)
        }
    }

    // ── the applications playing into it ──────────────────────────────────

    // One bar per stream, so a video can be turned down without turning the
    // machine down with it. Only there while something is playing.
    ColumnLayout {
        Layout.fillWidth: true

        visible: Audio.streams.length > 0

        spacing: Theme.stackSpacing

        Heading {
            text: "Apps"
        }

        Repeater {
            model: Audio.streams

            ColumnLayout {
                id: stream

                required property var modelData

                Layout.fillWidth: true

                spacing: Theme.space1

                Caption {
                    Layout.fillWidth: true

                    text: Audio.app(stream.modelData)
                    color: Theme.textMuted
                }

                Volume {
                    Layout.fillWidth: true

                    node: stream.modelData
                    label: Audio.app(stream.modelData)
                }
            }
        }
    }

    // ── input, with what it is actually hearing ───────────────────────────

    ColumnLayout {
        Layout.fillWidth: true

        visible: Audio.source !== null

        spacing: Theme.stackSpacing

        Heading {
            text: "Input"
        }

        Volume {
            Layout.fillWidth: true

            node: Audio.source
            input: true
        }

        // the level the microphone is picking up right now, which is the
        // only honest way to show that it is hearing anything
        Meter {
            Layout.fillWidth: true
            Layout.rightMargin: Theme.figureWidth + Theme.rowSpacing

            value: root.inputMuted ? 0 : monitor.peak
            fillColor: Theme.textDim
        }

        DeviceList {
            nodes: Audio.sources
            current: Audio.source

            onPicked: node => Audio.setDefaultSource(node)
        }
    }

    // Monitoring a node costs pipewire real work, so it only runs while this
    // panel is the one on screen.
    PwNodePeakMonitor {
        id: monitor

        node: Audio.source
        enabled: root.visible
    }

    // The devices a bar could be going through, with a check beside the one
    // it is. The rows reach out past the page margin so their hover ground
    // wraps the name rather than starting at it.
    component DeviceList: ColumnLayout {
        id: list

        required property var nodes
        required property PwNode current

        signal picked(PwNode node)

        Layout.fillWidth: true
        Layout.topMargin: Theme.space1

        spacing: 0

        Repeater {
            model: list.nodes

            ListRow {
                id: row

                required property var modelData
                required property int index

                readonly property bool selected: row.modelData === list.current

                Layout.fillWidth: true

                bleed: true
                rule: row.index < list.nodes.length - 1

                Accessible.name: Audio.label(row.modelData)

                onClicked: list.picked(row.modelData)

                Sans {
                    Layout.fillWidth: true

                    text: Audio.label(row.modelData)
                    color: row.selected ? Theme.text : Theme.textMuted
                }

                Caption {
                    text: Audio.bus(row.modelData)
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
