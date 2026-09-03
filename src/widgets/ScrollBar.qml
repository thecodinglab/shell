import QtQuick
import qs.theme
import qs.util

// The bar beside a list with more in it than fits.
//
// It is a sibling of the list rather than a child of it — anything declared
// inside a Flickable scrolls away with the content — and anchors itself just
// off that list's right edge, so the list reserves the gutter it stands in:
//
//     ListView { id: list; anchors.rightMargin: bar.overflowing ? bar.width : 0 }
//     ScrollBar { id: bar; flickable: list }
//
// While everything fits there is nothing to show and it takes itself off the
// screen entirely, which is most of the time.
Item {
    id: root

    required property Flickable flickable

    // the visible band, and the column of empty space around it that is still
    // wide enough to grab
    property int thickness: Theme.scrollThickness
    property int gutter: Theme.scrollGutter
    // so a very long list still leaves something to aim at
    property int minLength: Theme.px(24)

    readonly property real ratio: Math.min(1, root.flickable.visibleArea.heightRatio)
    readonly property bool overflowing: root.ratio < 1

    // 0..1, where the handle sits in the travel it has
    readonly property real position: {
        const room = 1 - root.ratio;
        return room > 0 ? Math.max(0, Math.min(1, root.flickable.visibleArea.yPosition / room)) : 0;
    }

    anchors.top: root.flickable.top
    anchors.bottom: root.flickable.bottom
    anchors.left: root.flickable.right

    width: root.gutter

    // it appears with the overflow that needs it, rather than snapping in
    opacity: root.overflowing ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.fadeDuration
        }
    }

    Rectangle {
        id: handle

        anchors.horizontalCenter: parent.horizontalCenter

        y: (root.height - height) * root.position

        width: root.thickness
        height: Math.max(root.minLength, root.height * root.ratio)

        radius: width / 2
        color: drag.pressed || drag.containsMouse ? Theme.textMuted : Theme.track

        Behavior on color {
            ColorAnimation {
                duration: Theme.fadeDuration
            }
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
            const travel = root.height - handle.height;
            const scrollable = root.flickable.contentHeight - root.flickable.height;
            if (travel <= 0 || scrollable <= 0)
                return;

            const fraction = Math.max(0, Math.min(1, (y - handle.height / 2) / travel));
            root.flickable.contentY = fraction * scrollable;
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
