import QtQuick
import QtQuick.Shapes
import qs.theme

// One arc of a ring: a band `thickness` wide along a circle `size` across,
// from `start` degrees clockwise of three o'clock, for `sweep` degrees.
//
// What a dial and a spinner are both drawn with — two of these each, the
// empty ring and the part of it that means something.
ShapePath {
    id: root

    required property real size
    property real thickness: Theme.gaugeThickness
    property real start: 0
    property real sweep: 360

    strokeColor: Theme.track
    strokeWidth: root.thickness
    fillColor: "transparent"
    capStyle: ShapePath.RoundCap

    PathAngleArc {
        centerX: root.size / 2
        centerY: root.size / 2
        // the stroke straddles the path, so the band's outside edge is the
        // item's edge only if the radius is pulled in by half
        radiusX: (root.size - root.thickness) / 2
        radiusY: radiusX

        startAngle: root.start
        sweepAngle: root.sweep
    }
}
