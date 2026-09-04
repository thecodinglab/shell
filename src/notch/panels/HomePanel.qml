pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.util
import qs.widgets
import qs.notch

// What the notch shows when it first unfolds: the time it was already
// showing, what is playing, how loud, and four doors further in.
//
// A column of modules, each on the one wash the surface has, and nothing
// between them but air. The clock is the only thing set large; everything
// else is a name, a line under it, and a control where there is something
// to set. The doors are the tiles and the head of the sound module, and each
// one leads to exactly one panel.
ColumnLayout {
    id: root

    required property var notch

    readonly property var link: Network.primary

    spacing: Theme.expandedSpacing

    // ── the collapsed notch, grown ────────────────────────────────────────
    // The dots stay where they were on the pill and the clock grows where it
    // was, so the eye follows both out of the pill and into the panel.

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.cardPadding
        Layout.rightMargin: Theme.cardPadding
        Layout.topMargin: Theme.px(2)
        Layout.bottomMargin: Theme.px(2)

        spacing: Theme.rowSpacing

        Dots {
            Layout.alignment: Qt.AlignVCenter

            screen: root.notch.modelData
        }

        Item {
            Layout.fillWidth: true
        }

        // The clock is the door to the notifications, the way it is on a
        // laptop: its hover ground reaches out past the header's margin so
        // the figures stay where they were on the grid. What is waiting is
        // counted beside it, and the count is there only when it is not
        // zero — a nought beside the clock is a thing to read for nothing.
        ListRow {
            id: clockHead

            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: -Theme.rowPadding
            Layout.bottomMargin: -Theme.rowPadding
            Layout.rightMargin: -Theme.rowPadding

            flat: true

            onClicked: root.notch.panel = "notifications"

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: Theme.px(2)

                visible: Notifs.count > 0

                spacing: Theme.px(4)

                Glyph {
                    Layout.alignment: Qt.AlignVCenter

                    text: Icons.bell
                    color: clockHead.hovered ? Theme.textBody : Theme.textDim

                    width: implicitWidth
                    font.pixelSize: Theme.fontSmall
                }

                Num {
                    Layout.alignment: Qt.AlignVCenter

                    text: String(Notifs.count)
                    color: clockHead.hovered ? Theme.textBody : Theme.textDim
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter

                spacing: 0

                Num {
                    Layout.alignment: Qt.AlignRight

                    text: Time.time
                    color: Theme.text

                    font.family: Theme.displayFamily
                    font.pixelSize: Theme.fontDisplay
                    font.weight: Font.Medium
                    font.letterSpacing: -Theme.fontDisplay * 0.02
                }

                Num {
                    Layout.alignment: Qt.AlignRight

                    text: Time.date
                    color: Theme.textDim
                }
            }
        }
    }

    // ── what is playing ───────────────────────────────────────────────────
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

    // ── sound ─────────────────────────────────────────────────────────────
    // The head of the module names it and says where the sound is going,
    // and is the way into the panel; the bar under it is the one thing
    // worth setting without going there. The microphone lives in the panel.

    Card {
        Layout.fillWidth: true

        ColumnLayout {
            spacing: Theme.px(10)

            ListRow {
                id: soundHead

                Layout.fillWidth: true
                // the row's hover ground reaches out past the module's own
                // content edge, so the name inside it stays on the grid
                Layout.leftMargin: -Theme.rowPadding
                Layout.rightMargin: -Theme.rowPadding
                Layout.topMargin: -Theme.rowPadding
                Layout.bottomMargin: -Theme.px(4)

                flat: true

                onClicked: root.notch.panel = "audio"

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: Theme.px(1)

                    Sans {
                        Layout.fillWidth: true

                        text: "Sound"
                        color: Theme.text

                        font.weight: Font.Medium
                    }

                    Caption {
                        Layout.fillWidth: true

                        text: Audio.sink ? Audio.label(Audio.sink) : "No output"
                    }
                }

                Glyph {
                    Layout.alignment: Qt.AlignVCenter

                    text: Icons.forward
                    color: soundHead.hovered ? Theme.textBody : Theme.textDim

                    font.pixelSize: Theme.fontSmall
                }
            }

            Slider {
                Layout.fillWidth: true

                icon: Icons.volume(Audio.volume, Audio.muted)
                // a muted device reads as silent rather than as whatever it
                // will go back to when it is unmuted
                value: Audio.muted ? 0 : Audio.volume

                onMoved: fraction => Audio.setVolume(Audio.sink, fraction)
                onIconClicked: Audio.toggleMute(Audio.sink)
            }

        }
    }

    // ── two doors ─────────────────────────────────────────────────────────
    // A lit disc means the thing is in use: a device on the line, a link
    // carrying an address. On but idle is the plain disc, and the line under
    // the name says which.

    RowLayout {
        Layout.fillWidth: true

        spacing: Theme.expandedSpacing

        Tile {
            Layout.fillWidth: true
            // both tiles get half the row regardless of what is in them
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            icon: {
                if (!Bt.enabled)
                    return Icons.bluetoothOff;
                return Bt.primary ? Icons.device(Bt.primary.icon) : Icons.bluetooth;
            }
            on: Bt.primary !== null
            title: "Bluetooth"
            subtitle: {
                if (!Bt.available)
                    return "No adapter";
                if (!Bt.enabled)
                    return "Off";
                if (Bt.primary)
                    return Bt.primary.batteryAvailable ? `${Bt.label(Bt.primary)} · ${Fmt.percent(Bt.primary.battery)}` : Bt.label(Bt.primary);
                return Bt.discovering ? "Scanning" : "Not connected";
            }

            onClicked: root.notch.panel = "bluetooth"
        }

        Tile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true

            icon: root.link ? Icons.link(root.link.kind) : Icons.networkOff
            on: Network.state === "connected"
            // named for what it is rather than for the setting: a machine
            // on a wire is on ethernet, not on "network"
            title: root.link ? Network.kindLabel(root.link.kind) : "Network"
            subtitle: {
                switch (Network.state) {
                case "connected":
                    return Network.address;
                case "linked":
                    return "No address";
                default:
                    return "Offline";
                }
            }
            subtitleColor: Network.state === "connected" ? Theme.textDim : Theme.urgent

            onClicked: root.notch.panel = "network"
        }
    }

    // ── the third door ────────────────────────────────────────────────────
    // Three dials rather than three bars. A ring is read as a quantity
    // without being read as a number — how full it is lands before the
    // figure inside it does — which is what a strip you glance at on the
    // way past is for, and it is the shell's own mark besides.

    ListRow {
        Layout.fillWidth: true

        padding: Theme.cardPadding

        onClicked: root.notch.panel = "resources"

        Repeater {
            model: [
                {
                    label: "cpu",
                    fraction: Cpu.usage
                },
                {
                    label: "memory",
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

                // an equal third each, taken from the strip rather than
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
