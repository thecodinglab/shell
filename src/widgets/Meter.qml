import QtQuick
import qs.theme

// A read-only bar under a figure. Nothing to grab, nothing to scroll.
Rectangle {
    id: root

    // 0..1
    property real value: 0
    property color fillColor: Theme.accent

    implicitHeight: Theme.meterHeight
    implicitWidth: Theme.px(52)

    radius: height / 2
    color: Theme.track

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: parent.height

        radius: height / 2
        color: root.fillColor

        Behavior on width {
            NumberAnimation {
                duration: Theme.fadeDuration
            }
        }
    }
}
