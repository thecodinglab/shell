pragma ComponentBehavior: Bound

import QtQuick
import qs.theme

// A history of samples as bars, oldest on the left.
//
// The number of slots is fixed rather than taken from the sample count, so a
// graph that has only been running for ten seconds is a mostly empty graph
// instead of three fat bars.
Item {
    id: root

    // 0..1 each, newest last
    property var values: []
    property int slots: 40
    // the newest few, picked out against the rest
    property int recent: 3

    property color pastColor: Theme.graphPast
    property color recentColor: Theme.accent

    implicitHeight: Theme.graphHeight

    // slot `index` counted back from the newest sample
    function sample(index: int): real {
        const offset = root.values.length - root.slots + index;
        return offset >= 0 ? (root.values[offset] ?? 0) : 0;
    }

    Row {
        id: row

        anchors.fill: parent

        spacing: Theme.px(2)

        Repeater {
            model: root.slots

            Item {
                id: slot

                required property int index

                width: (row.width - row.spacing * (root.slots - 1)) / root.slots
                height: row.height

                Rectangle {
                    anchors.bottom: parent.bottom

                    width: parent.width
                    // a floor, so an idle cpu still draws a baseline
                    height: Math.max(Theme.px(2), root.sample(slot.index) * parent.height)

                    // barely rounded: at this width a fully round cap turns a
                    // low sample into a dash and a high one into a lozenge,
                    // and a row of them stops reading as a bar chart
                    radius: Theme.px(1)
                    color: slot.index >= root.slots - root.recent ? root.recentColor : root.pastColor
                }
            }
        }
    }
}
