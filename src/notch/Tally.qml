import QtQuick
import qs.theme
import qs.services

// What stays of the notch on the top edge while it is put away and the
// microphone, the camera or the screen is in use: the light on a camera that
// says it is live.
//
// Put away, the notch is not there at all, and a dot that only showed on the
// pill would only show to someone who had already reached for it. Keeping
// the whole pill out for the length of a call would take the top of the
// screen back from the windows for an hour; so what stays is the least of
// it that still reads as the notch — a slot hanging from the edge where the
// notch hangs, ears and all, just big enough to hold the dot. Reaching the
// top edge brings the notch out over it, and the page says who is using
// what.
//
// It takes no clicks. It only says something, so a click on it belongs to
// whatever is behind it, and the notch leaves it out of its mask the way it
// leaves out the volume reading.
Item {
    id: root

    // The slab is out over it, and nothing of it can be seen: it stops
    // drawing, and does not move, until the slab goes back up.
    property bool covered: false

    // How far off the top edge it is, as a fraction of its own height: out is
    // 0, put away is 1 — the slab's measure, on its spring.
    readonly property alias slide: sliding.value
    // how far below the top edge it reaches right now, which is where the
    // notch hangs anything else from while it is put away
    readonly property int reach: slot.y + slot.height

    // the ears either side reach only as far as its straight sides do, the
    // way the slab's do — see `Notch.earReach`
    readonly property int earReach: Math.max(0, Math.min(Theme.tallyEar, slot.y + slot.height - slot.bottomLeftRadius))

    implicitWidth: Theme.tallyWidth + Theme.tallyEar * 2
    implicitHeight: Theme.tallyHeight

    visible: !root.covered && root.slide < 1

    Accessible.role: Accessible.Indicator
    Accessible.name: Privacy.summary

    // It comes and goes the way the slab does, out of the edge and back into
    // it, on the same spring; under the slab it is simply wherever it is
    // headed.
    Spring {
        id: sliding

        visible: !root.covered
        to: Privacy.active ? 0 : 1
    }

    Rectangle {
        id: slot

        anchors.horizontalCenter: parent.horizontalCenter

        // whole pixels, or its edge shimmers as it moves
        y: Math.round(-root.slide * slot.height)

        width: Theme.tallyWidth
        height: Theme.tallyHeight

        // square where it meets the edge and round below, the slab's shape
        // at the size of the thing it carries
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: slot.height / 2
        bottomRightRadius: slot.height / 2
        color: Theme.slab

        // in the colour that says on — see `Theme.privacy`
        Rectangle {
            anchors.centerIn: parent

            width: Theme.privacyDot
            height: Theme.privacyDot

            radius: width / 2
            color: Theme.privacy
        }
    }

    Ear {
        x: slot.x - root.earReach
        y: 0
        width: root.earReach
        height: root.earReach

        visible: root.earReach > 0
    }

    Ear {
        x: slot.x + slot.width
        y: 0
        width: root.earReach
        height: root.earReach

        visible: root.earReach > 0
        mirror: true
    }
}
