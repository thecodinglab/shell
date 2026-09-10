import QtQuick
import qs.theme

// A level, read and never set: a thin track and as much of it as the signal
// fills, on the same ink as a slider so it reads as the slider's reading
// rather than as a different kind of thing.
Item {
    id: root

    // 0..1
    property real value: 0
    property color fillColor: Theme.fill

    implicitHeight: Theme.meterHeight

    Rectangle {
        anchors.fill: parent

        radius: height / 2
        color: Theme.track
        clip: true

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value || 0))
            height: parent.height

            radius: height / 2
            color: root.fillColor

            // a signal is sampled a few times a second; the bar glides
            // between samples rather than stepping
            Behavior on width {
                NumberAnimation {
                    duration: 60
                }
            }
        }
    }
}
