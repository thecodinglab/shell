pragma ComponentBehavior: Bound

import QtQuick
import qs.theme

// Something is playing: four bars on the pill rising and falling out of
// step, the way the island shows a live activity at its trailing end. It
// says that, and nothing about what — the page under it has the cover and
// the name.
//
// The bars run only while they can be seen and something is playing; with
// reduced motion they stand still at their different heights, which still
// reads as a level rather than as nothing.
Row {
    id: root

    property bool playing: false

    spacing: Theme.waveBarGap

    Repeater {
        // where each bar rests, and how far it reaches, as shares of the height
        model: [[0.35, 0.9], [0.55, 1], [0.3, 0.75], [0.45, 0.95]]

        Item {
            id: column

            required property var modelData
            required property int index

            width: Theme.waveBarWidth
            height: Theme.waveHeight

            Rectangle {
                id: bar

                property real level: column.modelData[0]

                anchors.verticalCenter: parent.verticalCenter

                width: parent.width
                height: Math.max(width, Math.round(parent.height * bar.level))

                radius: width / 2
                color: Theme.accent

                SequentialAnimation on level {
                    running: root.playing && root.visible && Theme.motion > 0
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: column.modelData[1]
                        duration: Theme.waveDuration + column.index * Theme.waveStagger
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        to: column.modelData[0] * 0.6
                        duration: Theme.waveDuration + column.index * Theme.waveStagger
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }
}
