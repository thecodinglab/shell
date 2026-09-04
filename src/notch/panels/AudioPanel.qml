pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.theme
import qs.services
import qs.util
import qs.widgets
import qs.notch

// Where the sound goes and where it comes from.
//
// A module each way. Each has its bar at the top and the devices it could be
// going through underneath; one tap on a device makes it the default, and
// pipewire moves the streams that follow the default across on its own.
//
// Between them, a bar for each application that is playing, which is the same
// control one level down: the output bar sets what the machine is doing, and
// these set each application's share of it.
ColumnLayout {
    id: root

    required property var notch

    readonly property bool inputMuted: Audio.source?.audio?.muted ?? false

    spacing: Theme.expandedSpacing

    PanelHeader {
        Layout.fillWidth: true

        notch: root.notch
        title: "Sound"
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

            Volume {
                Layout.fillWidth: true

                node: Audio.sink
            }

            DeviceList {
                nodes: Audio.sinks
                current: Audio.sink

                onPicked: node => Audio.setDefaultSink(node)
            }
        }
    }

    // ── the applications playing into it ──────────────────────────────────

    // One bar per stream, so a video can be turned down without turning the
    // machine down with it. Only there while something is playing: pipewire
    // has no streams until an application opens one, and a module standing
    // empty says less than no module at all.
    Card {
        Layout.fillWidth: true

        visible: Audio.streams.length > 0

        ColumnLayout {
            spacing: Theme.px(10)

            Caption {
                Layout.bottomMargin: Theme.px(2)

                text: "Apps"
            }

            Repeater {
                model: Audio.streams

                ColumnLayout {
                    id: stream

                    required property var modelData

                    Layout.fillWidth: true

                    spacing: Theme.px(4)

                    Sans {
                        Layout.fillWidth: true

                        text: Audio.app(stream.modelData)
                    }

                    Volume {
                        Layout.fillWidth: true

                        node: stream.modelData
                    }
                }
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

            Volume {
                Layout.fillWidth: true

                node: Audio.source
                input: true
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

                pastColor: root.inputMuted ? Theme.track : Theme.alpha(Theme.text, 0.4)
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

        onTriggered: peaks.push(root.inputMuted ? 0 : monitor.peak)
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
