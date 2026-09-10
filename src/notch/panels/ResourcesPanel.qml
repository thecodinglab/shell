pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.services
import qs.util
import qs.widgets

// The three numbers worth watching, twice over: a dial for where each one is
// now, and the history beside it for how it got there.
//
// Each has a row to itself with a hairline between them: the dial at the
// left, the name and the figure behind it beside that, and the last few
// minutes as bars underneath.
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
                    history: Cpu.history,
                    span: Cpu.historySeconds
                },
                {
                    name: "Memory",
                    fraction: Memory.usage,
                    detail: `${Fmt.bytes(Memory.usedBytes)} of ${Fmt.bytes(Memory.totalBytes)}`,
                    history: Memory.history,
                    span: Memory.historySeconds
                },
                {
                    name: "Disk",
                    fraction: Disk.usage,
                    detail: `${Fmt.bytes(Disk.freeBytes)} free of ${Fmt.bytes(Disk.totalBytes)} on ${Config.diskPath}`,
                    history: Disk.history,
                    span: Disk.historySeconds
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
                        id: dial

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

                                text: `Last ${Fmt.span(reading.modelData.span)}`
                            }
                        }

                        Graph {
                            Layout.fillWidth: true

                            values: reading.modelData.history
                            // a machine under pressure reads the same colour
                            // in the dial and in the bars leading up to it
                            recentColor: dial.fillColor
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
