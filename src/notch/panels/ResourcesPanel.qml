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
// Each has a module to itself, and the room to be read: the dial is the
// larger of the two sizes here, and the name beside it says in words what
// the home strip only had room to say in three letters.
ColumnLayout {
    id: root

    required property var notch

    spacing: Theme.expandedSpacing

    PanelHeader {
        Layout.fillWidth: true

        title: "System"

        onBack: root.notch.panel = "home"
    }

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
                detail: `${Fmt.gibibytes(Memory.usedKb)} of ${Fmt.gibibytes(Memory.totalKb)} GiB`,
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

        Card {
            id: card

            required property var modelData

            Layout.fillWidth: true

            RowLayout {
                spacing: Theme.px(14)

                Gauge {
                    id: dial

                    Layout.alignment: Qt.AlignVCenter

                    // the larger of the two: here the dial is the subject of
                    // its own module rather than one of three in a strip
                    size: Theme.gaugeLarge

                    value: card.modelData.fraction
                    text: Fmt.percent(card.modelData.fraction)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    spacing: Theme.px(6)

                    RowLayout {
                        Layout.fillWidth: true

                        spacing: Theme.rowSpacing

                        ColumnLayout {
                            Layout.fillWidth: true

                            spacing: Theme.px(1)

                            Sans {
                                Layout.fillWidth: true

                                text: card.modelData.name
                                color: Theme.text

                                font.weight: Font.Medium
                            }

                            Caption {
                                Layout.fillWidth: true

                                visible: text !== ""

                                text: card.modelData.detail
                            }
                        }

                        // how much time the bars beside it cover, which is
                        // the only axis a histogram this small has room for
                        Caption {
                            Layout.alignment: Qt.AlignTop

                            text: `last ${Fmt.span(card.modelData.span)}`
                            color: Theme.textFaint
                        }
                    }

                    Graph {
                        Layout.fillWidth: true

                        values: card.modelData.history
                        // a machine under pressure reads the same colour in
                        // the dial and in the bars leading up to it
                        recentColor: dial.fillColor
                    }
                }
            }
        }
    }
}
