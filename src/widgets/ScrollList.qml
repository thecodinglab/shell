import QtQuick
import Quickshell
import qs.theme
import qs.util

// A list that grows the panel it is in until the notch would be half the
// screen tall, and scrolls from there, with a bar beside it once it does.
//
// The rows are diffed against what is already there — one arriving or
// leaving touches only itself, and one updated in place is the same row with
// new words on it — and they come and go the way the toasts do: a new one
// fades in and the rest make room, one leaving fades where it is and the
// rest close over the gap once it has gone, rather than up through it.
//
// The bar is a sibling of the list rather than a child of it — anything
// declared inside a Flickable scrolls away with the content — and the list
// gives up the gutter it stands in only while there is a bar to stand there.
// While everything fits there is no bar at all, which is most of the time.
Item {
    id: root

    property alias values: entries.values
    property alias delegate: list.delegate
    // as tall as the list may make itself
    property int maxHeight: 0

    implicitHeight: Math.min(list.contentHeight, root.maxHeight)

    ListView {
        id: list

        anchors.fill: parent
        anchors.rightMargin: bar.overflowing ? bar.width : 0

        clip: true
        spacing: Theme.listSpacing
        boundsBehavior: Flickable.StopAtBounds

        model: ScriptModel {
            id: entries
        }

        add: Transition {
            Fade {
                property: "opacity"
                from: 0
                to: 1
            }
        }

        displaced: Transition {
            Slide {
                property: "y"
            }
        }

        remove: Transition {
            Fade {
                property: "opacity"
                to: 0
            }
        }

        removeDisplaced: Transition {
            SequentialAnimation {
                PauseAnimation {
                    duration: Theme.fadeDuration
                }

                Slide {
                    property: "y"
                }
            }
        }
    }

    // ── the bar ───────────────────────────────────────────────────────────

    Item {
        id: bar

        readonly property real ratio: Math.min(1, list.visibleArea.heightRatio)
        readonly property bool overflowing: bar.ratio < 1

        // 0..1, where the handle sits in the travel it has
        readonly property real position: {
            const room = 1 - bar.ratio;
            return room > 0 ? Math.max(0, Math.min(1, list.visibleArea.yPosition / room)) : 0;
        }

        anchors.top: list.top
        anchors.bottom: list.bottom
        anchors.left: list.right

        // the column of empty space around the band, wide enough to grab
        width: Theme.scrollGutter

        // it appears with the overflow that needs it, rather than snapping in
        opacity: bar.overflowing ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Fade {}
        }

        Rectangle {
            id: handle

            anchors.horizontalCenter: parent.horizontalCenter

            y: (bar.height - height) * bar.position

            width: Theme.scrollThickness
            // so a very long list still leaves something to aim at
            height: Math.max(Theme.px(24), bar.height * bar.ratio)

            radius: width / 2
            color: drag.pressed || drag.containsMouse ? Theme.textMuted : Theme.track

            Behavior on color {
                ColorFade {}
            }
        }

        MouseArea {
            id: drag

            anchors.fill: parent

            // a drag that has left the bar is still a drag
            preventStealing: true
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            // the pointer grabs the middle of the handle, so the usable range
            // starts half a handle in
            function report(y: real): void {
                const travel = bar.height - handle.height;
                const scrollable = list.contentHeight - list.height;
                if (travel <= 0 || scrollable <= 0)
                    return;

                const fraction = Math.max(0, Math.min(1, (y - handle.height / 2) / travel));
                list.contentY = fraction * scrollable;
            }

            onPressed: event => drag.report(event.y)
            onPositionChanged: event => {
                if (drag.pressed)
                    drag.report(event.y);
            }

            // keep the notch open for as long as this drag lasts, even if it
            // wanders off the slab
            onPressedChanged: {
                if (drag.pressed)
                    Pointer.begin();
                else
                    Pointer.end();
            }

            Component.onDestruction: {
                if (drag.pressed)
                    Pointer.end();
            }
        }
    }
}
