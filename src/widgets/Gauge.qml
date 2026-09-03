import QtQuick
import QtQuick.Shapes
import qs.theme

// A dial: one fraction drawn as a ring, open at the bottom, with the figure
// it stands for sitting in the gap.
//
// The ring is a fixed size centred in whatever width it is given, so a row of
// gauges holds still while the numbers inside it change. Three abreast in the
// home tile, one to a card in the resources panel.
Item {
    id: root

    // 0..1
    property real value: 0
    // the figure the ring is standing in for, in the middle of it
    property string text: ""
    // ...and what is being measured, under that
    property string label: ""

    property int size: Theme.gaugeSize
    property int thickness: Theme.gaugeThickness
    // the ring is drawn inside the item rather than up against its edges, so
    // a gauge keeps its distance from whatever a layout sets it beside
    property int padding: Theme.gaugePadding

    // past here the ring is not just full, it is a problem
    property real warn: 0.9

    property color trackColor: Theme.track
    property color fillColor: root.fraction >= root.warn ? Theme.urgent : Theme.accent

    readonly property real fraction: Math.max(0, Math.min(1, root.value || 0))

    // the wedge the ring leaves open at the bottom, in degrees, and what is
    // left for it to draw in
    readonly property real gap: 108
    readonly property real sweep: 360 - root.gap

    // the circle the band encloses, and how much of the bottom of it the gap
    // opens up — which is the room the label has to sit in
    readonly property real inner: root.size / 2 - root.thickness
    readonly property real opening: 2 * root.inner * Math.sin(root.gap / 2 * Math.PI / 180)

    // The type inside the ring comes off the ring rather than off the panel's
    // type ramp: the ramp is a step up from the units the dial is drawn in,
    // so a figure taken from it runs into the band. Taken from the diameter
    // instead, the figure and its label keep their distance at any size.
    readonly property int valueSize: Math.round(root.size * 0.22)
    readonly property int labelSize: Math.round(root.size * 0.15)

    implicitWidth: root.size + root.padding * 2
    implicitHeight: root.size + root.padding * 2

    Shape {
        id: shape

        anchors.centerIn: parent

        width: root.size
        height: root.size

        // a thin arc reads as a staircase without it, and the curve renderer
        // antialiases one without the window having to ask for multisampling
        preferredRendererType: Shape.CurveRenderer

        // the empty ring, all the way round
        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: shape.width / 2
                centerY: shape.height / 2
                // the stroke straddles the path, so the band's outside edge
                // is the item's edge only if the radius is pulled in by half
                radiusX: (root.size - root.thickness) / 2
                radiusY: radiusX

                // degrees clockwise from three o'clock: half the gap past
                // straight down, which is the bottom left of the ring
                startAngle: 90 + root.gap / 2
                sweepAngle: root.sweep
            }
        }

        // ...and as much of it as the value fills
        ShapePath {
            strokeColor: root.fillColor
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Theme.fadeDuration
                }
            }

            PathAngleArc {
                centerX: shape.width / 2
                centerY: shape.height / 2
                radiusX: (root.size - root.thickness) / 2
                radiusY: radiusX

                startAngle: 90 + root.gap / 2
                sweepAngle: root.sweep * root.fraction

                // samples land every couple of seconds, so the ring is only
                // ever caught moving between two of them
                Behavior on sweepAngle {
                    NumberAnimation {
                        duration: Theme.expandDuration
                        easing.type: Theme.expandEasing
                    }
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent

        spacing: Math.round(root.size * 0.02)

        Num {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.text
            color: Theme.text

            font.pixelSize: root.valueSize
            font.weight: Font.Medium
        }

        Caption {
            anchors.horizontalCenter: parent.horizontalCenter

            // a label the ring has no room for is cut rather than drawn
            // through the band
            width: Math.min(implicitWidth, root.opening)

            // a dial with a name beside it does not repeat it inside
            visible: root.label !== ""

            text: root.label
            color: Theme.textDim

            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: root.labelSize
        }
    }
}
