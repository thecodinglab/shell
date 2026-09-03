import QtQuick
import qs.theme
import qs.util

// A track you can drag, click or scroll. It never moves itself: `moved` is a
// request, and `value` only changes when whatever owns it says so, so the
// handle can never drift away from the volume it is supposed to be showing.
Item {
    id: root

    // 0..1
    property real value: 0
    property color fillColor: Theme.accent
    // one notch of the wheel
    property real step: 0.02

    property bool knob: false
    property int knobSize: Theme.sliderKnob
    property color knobColor: Theme.text
    property int trackHeight: Theme.sliderHeight

    signal moved(real value)

    implicitWidth: Theme.px(120)
    implicitHeight: root.knob ? Math.max(root.knobSize, root.trackHeight) : root.trackHeight

    readonly property real _clamped: Math.max(0, Math.min(1, root.value))
    // with a knob the handle, not the fill, has to reach the end of the track
    readonly property real _travel: root.knob ? root.width - root.knobSize : root.width

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter

        width: parent.width
        height: root.trackHeight

        radius: height / 2
        color: Theme.track

        Rectangle {
            // the fill stops under the middle of the handle, not behind it
            width: root.knob ? root.knobSize / 2 + root._travel * root._clamped : parent.width * root._clamped
            height: parent.height

            radius: height / 2
            color: root.fillColor
        }
    }

    Rectangle {
        visible: root.knob

        x: root._travel * root._clamped
        anchors.verticalCenter: parent.verticalCenter

        width: root.knobSize
        height: width

        radius: height / 2
        color: root.knobColor
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        // a drag that starts on the track belongs to the track, even once it
        // has wandered off the panel
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function report(x: real): void {
            const travel = root._travel;
            if (travel <= 0)
                return;

            // the pointer grabs the middle of the handle, so the usable range
            // starts half a handle in
            const offset = root.knob ? root.knobSize / 2 : 0;
            root.moved(Math.max(0, Math.min(1, (x - offset) / travel)));
        }

        onPressed: event => mouse.report(event.x)
        onPositionChanged: event => {
            if (mouse.pressed)
                mouse.report(event.x);
        }

        onWheel: event => root.moved(root._clamped + (event.angleDelta.y > 0 ? root.step : -root.step))

        // keep the notch open for as long as this drag lasts, even if it
        // wanders off the slab
        onPressedChanged: {
            if (mouse.pressed)
                Pointer.begin();
            else
                Pointer.end();
        }

        Component.onDestruction: {
            if (mouse.pressed)
                Pointer.end();
        }
    }
}
