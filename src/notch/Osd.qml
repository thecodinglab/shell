import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.widgets

// A reading that appears for a moment when something is changed from the
// keyboard: the volume, set by its media keys, without the notch in sight.
//
// A pill hanging from the top edge, like a notification but smaller and with
// nothing to do to it: a glyph for what was set, a bar for how far, and the
// figure. It is not the control — the slider in the notch is — it is what the
// control would show, so it reads the same way: the fill is the ink, and the
// glyph and figure sit either side of it. Pressing the key again while it is
// up moves the fill and holds it there; left alone it goes back where it came
// from.
//
// It takes no clicks. Nothing on it does anything, so a click on it belongs
// to whatever is behind it, and the notch does not put it in its mask.
Rectangle {
    id: root

    // the glyph at the left end
    property string icon: ""
    // 0..1
    property real value: 0
    // the figure at the right end, already formatted
    property string text: ""

    // whether it is out, and the notch's cue to make room under the slab
    readonly property bool shown: hold.running
    // How far off the top edge it is, as a fraction of its own height: out
    // is 0, put away is 1. Animated on this rather than on `y`, so it can
    // ride under the slab without lagging it — see the slab itself.
    property real slide: root.shown ? 0 : 1

    // Bring it out, or keep it out: every call restarts the clock.
    function show(): void {
        hold.restart();
    }

    implicitWidth: Theme.osdWidth
    implicitHeight: row.implicitHeight + Theme.osdPadding * 2

    radius: height / 2
    color: Theme.slab

    border.width: 1
    border.color: Theme.slabBorder

    opacity: root.shown ? 1 : 0
    visible: opacity > 0

    Behavior on slide {
        NumberAnimation {
            duration: Theme.revealDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.expandCurve
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.revealDuration
        }
    }

    // it hangs over the desktop on its own, so it casts its own shadow
    Shadow {
        target: root
        radius: root.radius
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Theme.osdPadding + Theme.px(4)
        anchors.rightMargin: Theme.osdPadding + Theme.px(4)
        anchors.topMargin: Theme.osdPadding
        anchors.bottomMargin: Theme.osdPadding

        spacing: Theme.rowSpacing

        Glyph {
            Layout.alignment: Qt.AlignVCenter

            text: root.icon
            color: Theme.text

            font.pixelSize: Theme.fontTitle
        }

        // the track from the slider, read-only and thin: there is no pointer
        // here to aim it at
        Rectangle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            implicitHeight: Theme.osdTrackHeight

            radius: height / 2
            color: Theme.track
            clip: true

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.value))
                height: parent.height

                radius: height / 2
                color: Theme.fill

                // one press moves the fill one step; a run of them slides it
                Behavior on width {
                    NumberAnimation {
                        duration: Theme.fadeDuration
                        easing.type: Theme.expandEasing
                    }
                }
            }
        }

        Num {
            Layout.preferredWidth: Theme.figureWidth
            Layout.alignment: Qt.AlignVCenter

            text: root.text
            color: Theme.textMuted

            horizontalAlignment: Text.AlignRight
        }
    }

    Timer {
        id: hold

        interval: Theme.osdHold
    }
}
