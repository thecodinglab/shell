import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.theme
import qs.services
import qs.util
import qs.widgets

// One mpris player: its cover, what it is playing, and the transport.
//
// The cover and the name of the track are the module; the transport sits
// beside them, and the scrubber runs the whole width underneath with the
// two figures it needs at its ends, so the position is read across the
// object rather than out of a short bar between the buttons.
Card {
    id: root

    required property MprisPlayer player

    readonly property real length: root.player.lengthSupported ? root.player.length : 0
    readonly property real position: root.player.positionSupported ? root.player.position : 0
    readonly property real progress: root.length > 0 ? Math.min(1, root.position / root.length) : 0

    ColumnLayout {
        spacing: Theme.px(8)

        RowLayout {
            Layout.fillWidth: true

            spacing: Theme.px(12)

            ClippingRectangle {
                Layout.alignment: Qt.AlignVCenter

                implicitWidth: Theme.artSize
                implicitHeight: Theme.artSize

                radius: Theme.artRadius
                color: Theme.surfaceRaised

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
                Layout.alignment: Qt.AlignVCenter

                spacing: Theme.px(2)

                Sans {
                    Layout.fillWidth: true

                    text: root.player.trackTitle || "Unknown track"
                    color: Theme.text

                    font.weight: Font.Medium
                }

                Caption {
                    Layout.fillWidth: true

                    visible: text !== ""

                    text: [root.player.trackArtist, root.player.trackAlbum].filter(part => part).join(" — ")
                    color: Theme.textMuted
                }

                Caption {
                    Layout.fillWidth: true

                    // which player this is only matters when there is more
                    // than one of them; on its own, what it is playing says
                    // everything the name of the application would
                    visible: Media.players.length > 1

                    text: (root.player.identity || root.player.desktopEntry) ?? ""
                }
            }

            // ── the transport ─────────────────────────────────────────────

            RowLayout {
                Layout.alignment: Qt.AlignVCenter

                spacing: Theme.px(2)

                IconButton {
                    icon: Icons.previous
                    active: root.player.canGoPrevious

                    onClicked: root.player.previous()
                }

                IconButton {
                    icon: root.player.isPlaying ? Icons.pause : Icons.play
                    filled: true
                    active: root.player.canTogglePlaying

                    onClicked: root.player.togglePlaying()
                }

                IconButton {
                    icon: Icons.next
                    active: root.player.canGoNext

                    onClicked: root.player.next()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: Theme.rowSpacing

            Num {
                Layout.preferredWidth: Theme.figureWidth

                text: Fmt.duration(root.position)
                color: Theme.textDim
            }

            Slider {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                value: root.progress
                // a scrubber is read far more often than it is dragged, so
                // it is a hairline until a pointer comes for it
                trackHeight: Theme.scrubHeight
                activeHeight: Theme.scrubHeightActive
                fillColor: root.player.canSeek ? Theme.fill : Theme.textDim

                onMoved: fraction => {
                    if (root.player.canSeek && root.length > 0)
                        root.player.position = fraction * root.length;
                }
            }

            Num {
                Layout.preferredWidth: Theme.figureWidth

                text: Fmt.duration(root.length)
                color: Theme.textDim

                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
