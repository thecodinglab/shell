import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.util
import qs.widgets
import qs.notch

// What the notch shows when it first unfolds: the time it was already
// showing, what is playing, what it sounds like, and two tiles that lead
// somewhere.
ColumnLayout {
    id: root

    required property var notch

    spacing: Theme.expandedSpacing

    // ── the collapsed notch, still there ──────────────────────────────────
    // the dots and the clock stay where they were so the eye can follow them
    // out of the pill and into the panel

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.px(4)
        Layout.rightMargin: Theme.px(6)

        spacing: Theme.rowSpacing

        Dots {
            Layout.alignment: Qt.AlignVCenter

            screen: root.notch.modelData
        }

        Item {
            Layout.fillWidth: true
        }

        Mono {
            Layout.alignment: Qt.AlignBaseline

            text: Time.timeSeconds
            color: Theme.text

            font.pixelSize: Theme.fontClock
            font.weight: Font.Medium
        }

        Mono {
            Layout.alignment: Qt.AlignBaseline

            text: Time.date
            color: Theme.textDim

            font.pixelSize: Theme.fontMeta
        }
    }

    // ── media ─────────────────────────────────────────────────────────────
    // every player that is up, whatever is playing at the top, so a paused
    // video does not vanish the moment music starts somewhere else

    Repeater {
        model: Media.players

        MediaCard {
            required property var modelData

            Layout.fillWidth: true

            player: modelData
        }
    }

    // ── output and input, at a glance ─────────────────────────────────────

    Card {
        Layout.fillWidth: true

        ColumnLayout {
            spacing: Theme.px(8)

            VolumeRow {
                Layout.fillWidth: true

                node: Audio.sink
                icon: Icons.volume(Audio.volume, Audio.muted)
                muted: Audio.muted

                onOpen: root.notch.panel = "audio"
            }

            VolumeRow {
                Layout.fillWidth: true

                node: Audio.source
                icon: Audio.inputMuted ? Icons.microphoneMuted : Icons.microphone
                muted: Audio.inputMuted
                // the microphone is the quieter of the two, and reads that way
                fillColor: Theme.textMuted

                onOpen: root.notch.panel = "audio"
            }
        }
    }

    // ── the ways out ──────────────────────────────────────────────────────
    // one row per interface that is up, rather than one line for whichever
    // one was configured: a machine on ethernet and a tunnel at once is on
    // both, and which address a thing is reachable at depends on which

    Card {
        Layout.fillWidth: true

        ColumnLayout {
            spacing: Theme.px(8)

            // nothing is up, which is a statement rather than a list of none
            RowLayout {
                Layout.fillWidth: true

                spacing: Theme.rowSpacing
                visible: Network.interfaces.length === 0

                Glyph {
                    text: Icons.networkOff
                    color: Theme.urgent
                }

                Sans {
                    Layout.fillWidth: true

                    text: "Offline"
                    color: Theme.text
                }
            }

            Repeater {
                model: Network.interfaces

                RowLayout {
                    id: link

                    required property var modelData

                    Layout.fillWidth: true

                    spacing: Theme.rowSpacing

                    Glyph {
                        text: Icons.link(link.modelData.kind)
                        // the accent is for a link something can actually be
                        // sent over; one with no address gets the muted ink
                        // its address column has
                        color: link.modelData.state === "connected" ? Theme.accent : Theme.textMuted
                    }

                    Mono {
                        Layout.fillWidth: true

                        text: link.modelData.name
                        color: Theme.text

                        font.pixelSize: Theme.fontBody
                    }

                    Mono {
                        visible: link.modelData.state === "connected"

                        text: link.modelData.address
                        color: Theme.textMuted

                        font.pixelSize: Theme.fontMeta
                    }

                    Tag {
                        visible: link.modelData.state !== "connected"

                        text: "no address"
                    }
                }
            }
        }
    }

    // ── two tiles, each a way further in ──────────────────────────────────

    RowLayout {
        Layout.fillWidth: true

        spacing: Theme.px(10)

        ListRow {
            id: bluetoothTile

            Layout.fillWidth: true
            // both tiles get half the row regardless of what is in them
            Layout.preferredWidth: 1
            // ...and all of its height, so whichever of the two is taller sets
            // the height of the pair rather than leaving the other one
            // floating in the middle of a shorter box
            Layout.fillHeight: true

            // a connected device is worth saying, but not by washing one of
            // the two tiles in accent and leaving the other on the plain
            // ground — the pair reads as one row, so it says it in the glyph
            // and leaves the box alone
            readonly property bool connected: Bt.connected.length > 0

            onClicked: root.notch.panel = "bluetooth"

            Glyph {
                text: {
                    if (!Bt.enabled)
                        return Icons.bluetoothOff;
                    return Bt.primary ? Icons.device(Bt.primary.icon) : Icons.bluetooth;
                }
                color: bluetoothTile.connected ? Theme.accent : Theme.textMuted

                font.pixelSize: Theme.fontTitle
            }

            ColumnLayout {
                Layout.fillWidth: true
                // the name and its subtitle sit in the middle of whatever
                // height the row settles on rather than hanging from the top
                Layout.alignment: Qt.AlignVCenter

                spacing: Theme.px(1)

                Sans {
                    Layout.fillWidth: true

                    text: Bt.primary ? Bt.label(Bt.primary) : (Bt.enabled ? "Bluetooth" : "Bluetooth off")
                    color: Theme.text

                    font.weight: Font.Medium
                }

                Mono {
                    Layout.fillWidth: true

                    text: {
                        if (!Bt.available)
                            return "no adapter";
                        if (!Bt.enabled)
                            return "disabled";
                        if (Bt.primary)
                            return Bt.primary.batteryAvailable ? `connected · ${Fmt.percent(Bt.primary.battery)}` : "connected";
                        return Bt.discovering ? "scanning" : `${Bt.devices.length} known`;
                    }
                    color: Theme.textMuted
                }
            }

            Mono {
                text: Icons.forward
            }
        }

        // Three dials rather than three figures: a percentage written out is a
        // different width every time it changes, and three of them side by
        // side pushed each other around the tile every couple of seconds. A
        // ring is the same size at 7% as it is at 100%.
        ListRow {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            onClicked: root.notch.panel = "resources"

            Repeater {
                model: [
                    {
                        label: "cpu",
                        fraction: Cpu.usage
                    },
                    {
                        label: "mem",
                        fraction: Memory.usage
                    },
                    {
                        label: "disk",
                        fraction: Disk.usage
                    }
                ]

                Gauge {
                    id: dial

                    required property var modelData

                    // an equal third each, taken from the tile rather than
                    // from what is written inside them
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignVCenter

                    value: dial.modelData.fraction
                    text: Fmt.percent(dial.modelData.fraction)
                    label: dial.modelData.label
                }
            }
        }
    }
}
