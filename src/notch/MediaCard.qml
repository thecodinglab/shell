import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.theme
import qs.services
import qs.util
import qs.widgets

// One mpris player: its cover, what it is playing, and the transport.
Card {
    id: root

    required property MprisPlayer player

    readonly property real length: root.player.lengthSupported ? root.player.length : 0
    readonly property real position: root.player.positionSupported ? root.player.position : 0
    readonly property real progress: root.length > 0 ? Math.min(1, root.position / root.length) : 0

    RowLayout {
        spacing: Theme.px(12)

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop

            implicitWidth: Theme.artSize
            implicitHeight: Theme.artSize

            radius: Theme.px(10)
            color: Theme.surfaceHover

            Image {
                id: art

                anchors.fill: parent

                source: root.player.trackArtUrl
                asynchronous: true
                fillMode: Image.PreserveAspectCrop

                sourceSize.width: Theme.artSize
                sourceSize.height: Theme.artSize
            }

            Text {
                anchors.centerIn: parent

                visible: art.status !== Image.Ready

                text: Icons.music
                color: Theme.textDim

                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontTitle
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            // the cover sets the height of the card; filling it puts the
            // transport level with the bottom of the artwork
            Layout.minimumHeight: Theme.artSize

            spacing: Theme.px(8)

            ColumnLayout {
                Layout.fillWidth: true

                spacing: Theme.px(2)

                Sans {
                    Layout.fillWidth: true

                    text: root.player.trackTitle || "Unknown track"
                    color: Theme.text

                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.DemiBold
                }

                Sans {
                    Layout.fillWidth: true

                    text: [root.player.trackArtist, root.player.trackAlbum].filter(part => part).join("  —  ")
                    color: Theme.textMuted

                    font.pixelSize: Theme.fontMeta
                }

                Mono {
                    Layout.fillWidth: true

                    text: (root.player.identity || root.player.desktopEntry).toLowerCase()
                }
            }

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                Layout.fillWidth: true

                spacing: Theme.px(6)

                Slider {
                    Layout.fillWidth: true

                    value: root.progress
                    knob: root.player.canSeek
                    knobSize: Theme.px(8)
                    knobColor: Theme.accent
                    trackHeight: Theme.px(3)

                    onMoved: fraction => Media.seek(root.player, fraction)
                }

                RowLayout {
                    Layout.fillWidth: true

                    spacing: Theme.rowSpacing

                    Mono {
                        text: Fmt.duration(root.position)
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: Theme.px(14)

                        IconButton {
                            icon: Icons.previous
                            active: root.player.canGoPrevious

                            onClicked: Media.previous(root.player)
                        }

                        IconButton {
                            icon: root.player.isPlaying ? Icons.pause : Icons.play
                            filled: true
                            active: root.player.canTogglePlaying

                            onClicked: Media.toggle(root.player)
                        }

                        IconButton {
                            icon: Icons.next
                            active: root.player.canGoNext

                            onClicked: Media.next(root.player)
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Mono {
                        text: Fmt.duration(root.length)
                    }
                }
            }
        }
    }
}
