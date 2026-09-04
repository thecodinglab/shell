import QtQuick
import QtQuick.Shapes
import qs.theme

// A ring with a bite taken out of it, turning.
//
// For the waits nobody can put a number on — a handshake with a headset is
// done when the headset says so — where a progress bar would be a lie.
Item {
    id: root

    implicitWidth: Theme.spinnerSize
    implicitHeight: Theme.spinnerSize

    Shape {
        anchors.centerIn: parent

        width: Theme.spinnerSize
        height: Theme.spinnerSize

        // a band this thin reads as a staircase without the curve renderer
        preferredRendererType: Shape.CurveRenderer

        // the ring it runs around
        Arc {
            size: Theme.spinnerSize
            thickness: Theme.spinnerThickness
        }

        // ...and the part of it that is moving
        Arc {
            size: Theme.spinnerSize
            thickness: Theme.spinnerThickness
            sweep: 110
            strokeColor: Theme.accent
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
