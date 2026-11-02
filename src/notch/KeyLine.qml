import QtQuick
import QtQuick.Shapes
import qs.theme

// The line round the open sheet, the way a key line is drawn round the island
// on a phone to tell it from what is under it: the bezel is near black, and
// so is many a window it opens over, and without it the sheet's edge would be
// only where its shadow starts.
//
// It runs down the ear on the left, the left side, round the bottom corners
// and back up the right side and its ear, and never along the top: the top is
// the edge of the screen, and the sheet is part of it. It sits just inside
// the outline rather than across it, so the edge against the desktop stays
// the slab's own.
//
// It stands beside `target` rather than in it — the slab clips what it holds,
// and the ears are outside it — reaching from the top of the screen to the
// slab's foot, and from the outside of one ear to the outside of the other.
Shape {
    id: root

    // the slab it runs round, a sibling of this, hanging from the top edge
    required property Item target
    // the slab's bottom corners, and how far its ears reach out and down
    property real radius: 0
    property real ear: 0

    // half the stroke, by which the line is pulled in off the outline
    readonly property real half: Theme.keyLineWidth / 2
    // the slab's left side, its right side and its foot, in this item's own
    // coordinates
    readonly property real near: root.ear
    readonly property real far: root.ear + root.target.width
    readonly property real foot: root.height

    x: root.target.x - root.ear
    y: 0
    width: root.target.width + root.ear * 2
    height: Math.max(0, root.target.y + root.target.height)

    visible: root.opacity > 0 && root.height > 0

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "transparent"
        strokeColor: Theme.bezel.keyLine
        strokeWidth: Theme.keyLineWidth
        capStyle: ShapePath.FlatCap
        joinStyle: ShapePath.RoundJoin

        // off the top of the screen, on the circle the left ear is scooped
        // out of...
        startX: 0
        startY: -root.half

        // ...round it to the side of the slab...
        PathArc {
            x: root.near + root.half
            y: root.ear
            radiusX: root.ear + root.half
            radiusY: root.ear + root.half
            direction: PathArc.Clockwise
        }

        // ...down it, round the foot...
        PathLine {
            x: root.near + root.half
            y: root.foot - root.radius
        }

        PathArc {
            x: root.near + root.radius
            y: root.foot - root.half
            radiusX: root.radius - root.half
            radiusY: root.radius - root.half
            direction: PathArc.Counterclockwise
        }

        PathLine {
            x: root.far - root.radius
            y: root.foot - root.half
        }

        PathArc {
            x: root.far - root.half
            y: root.foot - root.radius
            radiusX: root.radius - root.half
            radiusY: root.radius - root.half
            direction: PathArc.Counterclockwise
        }

        // ...and back up the other side and out along its ear
        PathLine {
            x: root.far - root.half
            y: root.ear
        }

        PathArc {
            x: root.width
            y: -root.half
            radiusX: root.ear + root.half
            radiusY: root.ear + root.half
            direction: PathArc.Clockwise
        }
    }
}
