import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.theme
import qs.services
import qs.util
import qs.widgets

// One mpris player: its cover, what it is playing, and the transport,
// straight on the sheet.
//
// The cover and the name of the track are the section; the transport sits
// beside them, and the scrubber runs the whole width underneath with the
// two figures it needs at its ends.
ColumnLayout {
    id: root

    required property MprisPlayer player

    readonly property real length: root.player.lengthSupported ? root.player.length : 0
    readonly property real position: root.player.positionSupported ? root.player.position : 0
    readonly property real progress: root.length > 0 ? Math.min(1, root.position / root.length) : 0

    spacing: Theme.stackSpacing

    RowLayout {
        Layout.fillWidth: true

        spacing: Theme.space3

        // the cover: the image once it is here, a breathing block while it is
        // on its way, and a note when there is none
        ClippingRectangle {
            Layout.alignment: Qt.AlignVCenter

            implicitWidth: Theme.artSize
            implicitHeight: Theme.artSize

            radius: Theme.radiusSmall
            color: Theme.surface

            Image {
                id: art

                anchors.fill: parent

                source: root.player.trackArtUrl
                asynchronous: true
                fillMode: Image.PreserveAspectCrop

                sourceSize.width: Theme.artSize
                sourceSize.height: Theme.artSize
            }

            Skeleton {
                anchors.fill: parent

                visible: art.status === Image.Loading

                radius: 0
            }

            Text {
                anchors.centerIn: parent

                visible: art.status === Image.Null || art.status === Image.Error

                text: Icons.music
                color: Theme.textDim

                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontTitle
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            spacing: Theme.lineGap

            Sans {
                Layout.fillWidth: true

                text: root.player.trackTitle || "Unknown track"

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
                // than one of them
                visible: Media.players.length > 1

                text: (root.player.identity || root.player.desktopEntry) ?? ""
            }
        }

        // ── the transport ─────────────────────────────────────────────────

        RowLayout {
            Layout.alignment: Qt.AlignVCenter

            spacing: Theme.space1

            IconButton {
                icon: Icons.previous
                label: "Previous"
                enabled: root.player.canGoPrevious

                onClicked: root.player.previous()
            }

            IconButton {
                icon: root.player.isPlaying ? Icons.pause : Icons.play
                label: root.player.isPlaying ? "Pause" : "Play"
                filled: true
                enabled: root.player.canTogglePlaying
                size: Theme.space8

                onClicked: root.player.togglePlaying()
            }

            IconButton {
                icon: Icons.next
                label: "Next"
                enabled: root.player.canGoNext

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

            label: "Position"
            value: root.progress
            // a scrubber is read far more often than it is dragged, so
            // it is a hairline until a pointer comes for it
            trackHeight: Theme.scrubHeight
            activeHeight: Theme.scrubHeightActive
            fillColor: root.player.canSeek ? Theme.fill : Theme.textFaint

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
