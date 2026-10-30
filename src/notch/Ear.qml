import QtQuick
import QtQuick.Shapes
import qs.theme

// Where a side of the notch meets the top edge of the screen: the corner
// between them filled in and cut back to a quarter of a circle, so the side
// flares out into the edge rather than standing on it at a right angle. It
// is what makes the notch read as part of the edge it hangs from, the way
// the one on a macbook is part of the bezel.
//
// Drawn for the left side, standing against the notch at its right; `mirror`
// turns it round for the right side.
Shape {
    id: root

    property bool mirror: false
    property color color: Theme.slab

    // the radius of the cut, and the size of the square it is cut from
    readonly property real size: Math.min(width, height)

    preferredRendererType: Shape.CurveRenderer

    transform: Scale {
        origin.x: root.width / 2
        xScale: root.mirror ? -1 : 1
    }

    ShapePath {
        fillColor: root.color
        strokeWidth: -1

        // along the top edge, down the notch's side, and back up to where it
        // started along a quarter circle bowed in toward the corner
        startX: 0
        startY: 0

        PathLine {
            x: root.size
            y: 0
        }

        PathLine {
            x: root.size
            y: root.size
        }

        PathArc {
            x: 0
            y: 0
            radiusX: root.size
            radiusY: root.size
            direction: PathArc.Clockwise
        }
    }
}
