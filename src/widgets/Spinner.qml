import QtQuick
import QtQuick.Shapes
import qs.theme

// A ring with a bite taken out of it, turning.
//
// For the waits nobody can put a number on — a handshake with a headset is
// done when the headset says so — where a progress bar would be a lie.
Item {
    id: root

    property int size: Theme.spinnerSize
    property int thickness: Theme.spinnerThickness
    property color color: Theme.accent
    property color trackColor: Theme.track

    // how much of the ring the moving part covers, in degrees
    property real arc: 110

    implicitWidth: root.size
    implicitHeight: root.size

    Shape {
        id: shape

        anchors.centerIn: parent

        width: root.size
        height: root.size

        // a band this thin reads as a staircase without the curve renderer
        preferredRendererType: Shape.CurveRenderer

        // the ring it runs around
        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            fillColor: "transparent"

            PathAngleArc {
                centerX: shape.width / 2
                centerY: shape.height / 2
                // the stroke straddles the path, so the band's outside edge
                // is the item's edge only if the radius is pulled in by half
                radiusX: (root.size - root.thickness) / 2
                radiusY: radiusX

                startAngle: 0
                sweepAngle: 360
            }
        }

        // ...and the part of it that is moving
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: shape.width / 2
                centerY: shape.height / 2
                radiusX: (root.size - root.thickness) / 2
                radiusY: radiusX

                startAngle: 0
                sweepAngle: root.arc
            }
        }

        // Only while it is on screen: a panel that has been folded away still
        // exists, and an animation nobody can see is just a wakeup.
        RotationAnimation on rotation {
            running: root.visible

            from: 0
            to: 360
            duration: Theme.spinDuration
            loops: Animation.Infinite
        }
    }
}
