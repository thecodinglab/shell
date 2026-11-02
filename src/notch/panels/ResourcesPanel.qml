pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.services
import qs.util
import qs.widgets

// The three numbers worth watching: a dial for where each one is now, and,
// for the two that move, the history beside it for how it got there. A disk
// does not fill up on a scale of minutes, so its bars would only ever be a
// flat line.
//
// Each has a row to itself with a hairline between them: the dial at the
// left, the name and the figure behind it beside that, and the last few
// minutes as bars underneath. Dials and bars alike are in the ink, the way
// a reading is; only a dial past nine tenths turns red.
ColumnLayout {
    id: root

    required property var notch

    spacing: Theme.stackSpacing

    PanelHeader {
        Layout.fillWidth: true

        notch: root.notch
        title: "System"
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.space1

        spacing: Theme.space3

        Repeater {
            model: [
                {
                    name: "Processor",
                    fraction: Cpu.usage,
                    detail: Cpu.threads > 0 ? `${Cpu.threads} threads` : "",
                    graph: true,
                    history: Cpu.history,
                    span: Cpu.historySeconds
                },
                {
                    name: "Memory",
                    fraction: Memory.usage,
                    detail: `${Fmt.bytes(Memory.usedBytes)} of ${Fmt.bytes(Memory.totalBytes)}`,
                    graph: true,
                    history: Memory.history,
                    span: Memory.historySeconds
                },
                {
                    name: "Disk",
                    fraction: Disk.usage,
                    detail: `${Fmt.bytes(Disk.freeBytes)} free of ${Fmt.bytes(Disk.totalBytes)} on ${Config.diskPath}`,
                    graph: false,
                    history: [],
                    span: 0
                }
            ]

            ColumnLayout {
                id: reading

                required property var modelData
                required property int index

                Layout.fillWidth: true

                spacing: Theme.space3

                RowLayout {
                    Layout.fillWidth: true

                    spacing: Theme.space3

                    Gauge {

                        Layout.alignment: Qt.AlignVCenter

                        value: reading.modelData.fraction
                        text: Fmt.percent(reading.modelData.fraction)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        spacing: Theme.space2

                        RowLayout {
                            Layout.fillWidth: true

                            spacing: Theme.rowSpacing

                            Label {
                                Layout.fillWidth: true

                                title: reading.modelData.name
                                caption: reading.modelData.detail
                            }

                            // how much time the bars beside it cover, which
                            // is the only axis a histogram this small has
                            // room for
                            Caption {
                                Layout.alignment: Qt.AlignTop

                                visible: reading.modelData.graph

                                // "past", not "last": "last 80s" reads as
                                // a decade
                                text: `Past ${Fmt.span(reading.modelData.span)}`
                            }
                        }

                        Graph {
                            Layout.fillWidth: true

                            visible: reading.modelData.graph

                            values: reading.modelData.history
                        }
                    }
                }

                Rule {
                    visible: reading.index < 2
                }
            }
        }
    }
}
