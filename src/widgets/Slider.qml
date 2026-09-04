import QtQuick
import qs.theme
import qs.util

// A track you can drag, click or scroll, with the glyph for what it sets
// riding inside the fill.
//
// There is no handle: the edge of the fill is the value, and the whole track
// is the target. A knob is a small thing to hit on a bar that is already the
// right shape to hit, and it puts a second marker on a track that already had
// one — where the colour changes. Without it the control is the reading.
//
// The glyph sits at the left end, on the fill when the fill reaches it and on
// the empty track when it does not, and swaps its ink as the edge passes
// over it. That is what tells a slider at nothing from a slider that is not
// there: the mark stays, the bar behind it goes.
//
// It never moves itself: `moved` is a request, and `value` only changes when
// whatever owns it says so, so the fill can never drift away from the volume
// it is supposed to be showing.
Item {
    id: root

    // 0..1
    property real value: 0
    // the glyph inside the left end of the track; none for a bare scrubber
    property string icon: ""
    property color fillColor: Theme.fill
    // one notch of the wheel
    property real step: 0.02

    property int trackHeight: Theme.sliderHeight
    // A scrubber is read far more often than it is dragged, so it can be
    // drawn thinner than it is aimed at — it grows to meet the pointer that
    // is coming for it. A control that is only ever dragged is already the
    // size of its target and stays put.
    property int activeHeight: root.trackHeight

    signal moved(real value)
    // the glyph was pressed rather than the track: mute, for a volume
    signal iconClicked

    readonly property real fraction: Math.max(0, Math.min(1, root.value))
    readonly property int railHeight: mouse.containsMouse || mouse.pressed ? root.activeHeight : root.trackHeight
    // the fill has reached past the middle of the glyph, so the glyph is
    // drawn on it rather than on the track
    readonly property bool covered: rail.width * root.fraction > root.trackHeight / 2

    implicitWidth: Theme.px(120)
    implicitHeight: Math.max(root.trackHeight, root.activeHeight)

    Rectangle {
        id: rail

        anchors.verticalCenter: parent.verticalCenter

        width: parent.width
        height: root.railHeight

        radius: height / 2
        color: Theme.track
        // the fill is a child, so it is clipped to the rail's own round ends
        // rather than drawing a second pair of them part way along it
        clip: true

        Behavior on height {
            Ease {}
        }

        Rectangle {
            width: rail.width * root.fraction
            height: rail.height

            radius: height / 2
            color: root.fillColor
        }
    }

    Text {
        id: glyph

        // centred in a square cell at the left end of the track
        x: (root.trackHeight - width) / 2
        anchors.verticalCenter: parent.verticalCenter

        visible: root.icon !== ""

        text: root.icon
        color: root.covered ? Theme.onFill : Theme.textMuted

        font.family: Theme.monoFamily
        font.pixelSize: Theme.fontTitle

        Behavior on color {
            ColorFade {}
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        // the rail can be thinner than the item; the whole item is still the
        // target, so a pointer near the track is on it
        hoverEnabled: true
        // a drag that starts on the track belongs to the track, even once it
        // has wandered off the panel
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        // whether a press landed on the glyph's cell, and whether it has
        // since turned into a drag along the track
        property bool onIcon: false
        property bool dragged: false

        function report(x: real): void {
            if (root.width <= 0)
                return;

            root.moved(Math.max(0, Math.min(1, x / root.width)));
        }

        // A press on the glyph is held back: if it is released where it
        // landed it was a click on the glyph, and if it moves it was the
        // start of a drag and is reported like one.
        onPressed: event => {
            mouse.onIcon = root.icon !== "" && event.x < root.trackHeight;
            mouse.dragged = false;

            if (!mouse.onIcon)
                mouse.report(event.x);
        }

        onPositionChanged: event => {
            if (!mouse.pressed)
                return;

            if (mouse.onIcon && Math.abs(event.x - root.trackHeight / 2) < root.trackHeight / 2)
                return;

            mouse.dragged = true;
            mouse.report(event.x);
        }

        onReleased: {
            if (mouse.onIcon && !mouse.dragged)
                root.iconClicked();
        }

        onWheel: event => root.moved(root.fraction + (event.angleDelta.y > 0 ? root.step : -root.step))

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
