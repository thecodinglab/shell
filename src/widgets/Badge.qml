import QtQuick
import qs.theme

// A count on the corner of a control: how many are waiting behind it. Not
// there at all at nought, since a nought is a thing to read for nothing.
//
// It pops out of the corner when the first one arrives and shrinks back
// into it when the last one goes, and gives a small start each time the
// count goes up in between, so a new arrival is noticed without being read.
Rectangle {
    id: root

    property int count: 0

    // the count as it was, to tell a new arrival from one being dealt with
    property int last: 0

    Component.onCompleted: root.last = root.count

    onCountChanged: {
        if (root.count > root.last && root.last > 0)
            start.nudge(8);
        root.last = root.count;
    }

    implicitHeight: Theme.badgeHeight
    implicitWidth: Math.max(implicitHeight, figure.implicitWidth + Theme.space1 * 2)

    radius: height / 2
    color: Theme.accent

    scale: grow.value * start.value
    visible: root.scale > 0.01

    // the way hyprland pops a window in
    Spring {
        id: grow

        leaf: "windows"
        visible: root.parent?.visible ?? true
        to: root.count > 0 ? 1 : 0
    }

    // ...and the start, a knock it springs back from, so a run of arrivals
    // adds up rather than starting it again each time
    Spring {
        id: start

        leaf: "windows"
        visible: root.parent?.visible ?? true
        to: 1
    }

    Num {
        id: figure

        anchors.centerIn: parent

        text: String(root.count)
        color: Theme.onAccent

        font.weight: Font.Medium
    }
}
