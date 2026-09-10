import QtQuick
import qs.theme

// The place something will be once it has loaded: a block of the raised
// ground, the shape of what is coming. It breathes, so a block that is still
// loading is told from one that is simply empty — unless motion is off.
Rectangle {
    id: root

    radius: Theme.radiusSmall
    color: Theme.surface

    SequentialAnimation on opacity {
        running: root.visible && Theme.motion > 0
        loops: Animation.Infinite

        NumberAnimation {
            to: 0.55
            duration: Theme.pulseDuration
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            to: 1
            duration: Theme.pulseDuration
            easing.type: Easing.InOutSine
        }
    }
}
