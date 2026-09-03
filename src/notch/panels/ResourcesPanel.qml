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
ColumnLayout {
    id: root

    required property var notch

    spacing: Theme.px(10)

    PanelHeader {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.px(4)

        title: "Resources"

        onBack: root.notch.panel = "home"

        Caption {
            text: {
                switch (Network.state) {
                case "connected":
                    return `${Network.name} · ${Network.address}`;
                case "linked":
                    return `${Network.name} · no address`;
                default:
                    return "offline";
                }
            }
            color: Network.state === "connected" ? Theme.textDim : Theme.urgent

            font.capitalization: Font.MixedCase
        }
    }

    Repeater {
        model: [
            {
                label: "cpu",
                fraction: Cpu.usage,
                detail: Cpu.threads > 0 ? `${Cpu.threads} threads` : "processor",
                history: Cpu.history,
                span: Cpu.historySeconds
            },
            {
                label: "mem",
                fraction: Memory.usage,
                detail: `${Fmt.gibibytes(Memory.usedKb)}G of ${Fmt.gibibytes(Memory.totalKb)}G`,
                history: Memory.history,
                span: Memory.historySeconds
            },
            {
                label: "disk",
                fraction: Disk.usage,
                detail: `${Config.diskPath} · ${Fmt.bytes(Disk.freeBytes)} free of ${Fmt.bytes(Disk.totalBytes)}`,
                history: Disk.history,
                span: Disk.historySeconds
            }
        ]

        Card {
            id: card

            required property var modelData

            Layout.fillWidth: true

            RowLayout {
                spacing: Theme.rowSpacing

                Gauge {
                    id: dial

                    Layout.alignment: Qt.AlignVCenter

                    size: Theme.gaugeLarge

                    value: card.modelData.fraction
                    text: Fmt.percent(card.modelData.fraction)
                    label: card.modelData.label
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: Theme.px(6)

                    RowLayout {
                        Layout.fillWidth: true

                        spacing: Theme.rowSpacing

                        Mono {
                            Layout.fillWidth: true

                            text: card.modelData.detail
                            color: Theme.textMuted

                            font.pixelSize: Theme.fontMeta
                        }

                        // how much time the bars beside it cover, which is
                        // the only axis a histogram this small has room for
                        Caption {
                            text: `last ${Fmt.span(card.modelData.span)}`
                            color: Theme.textFaint

                            font.pixelSize: Theme.fontTiny
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
