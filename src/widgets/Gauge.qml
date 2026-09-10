import QtQuick
import QtQuick.Shapes
import qs.theme

// A dial: one fraction drawn as a ring, open at the bottom, with the figure
// it stands for sitting in the gap.
//
// The ring is a fixed size centred in whatever width it is given, so a row of
// gauges holds still while the numbers inside it change.
Item {
    id: root

    // 0..1
    property real value: 0
    // the figure the ring is standing in for, in the middle of it
    property string text: ""

    property int size: Theme.gaugeSize

    readonly property real fraction: Math.max(0, Math.min(1, root.value || 0))
    // past nine tenths the ring is not just full, it is a problem
    readonly property color fillColor: root.fraction >= 0.9 ? Theme.urgent : Theme.accent

    // the wedge the ring leaves open at the bottom, in degrees
    readonly property real gap: 108
    // degrees clockwise from three o'clock: half the gap past straight
    // down, which is the bottom left of the ring
    readonly property real start: 90 + root.gap / 2

    // the ring is drawn inside the item rather than up against its edges, so
    // a gauge keeps its distance from whatever a layout sets it beside
    implicitWidth: root.size + Theme.gaugePadding * 2
    implicitHeight: root.size + Theme.gaugePadding * 2

    Shape {
        anchors.centerIn: parent

        width: root.size
        height: root.size

        // a thin arc reads as a staircase without it, and the curve renderer
        // antialiases one without the window having to ask for multisampling
        preferredRendererType: Shape.CurveRenderer

        // the empty ring, all the way round
        Arc {
            size: root.size
            start: root.start
            sweep: 360 - root.gap
        }

        // ...and as much of it as the value fills
        Arc {
            size: root.size
            start: root.start
            sweep: (360 - root.gap) * root.fraction
            strokeColor: root.fillColor

            Behavior on strokeColor {
                ColorFade {}
            }

            // samples land every couple of seconds, so the ring is only
            // ever caught moving between two of them
            Behavior on sweep {
                NumberAnimation {
                    duration: Theme.expandDuration
                    easing.type: Theme.expandEasing
                }
            }
        }
    }

    Num {
        anchors.centerIn: parent

        text: root.text
        color: Theme.text

        font.pixelSize: Theme.fontTitle
        font.weight: Font.Medium
    }
}
