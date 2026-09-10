import QtQuick
import qs.theme

// A count on the corner of a control: how many are waiting behind it. Not
// there at all at nought, since a nought is a thing to read for nothing.
Rectangle {
    id: root

    property int count: 0

    visible: root.count > 0

    implicitHeight: Theme.badgeHeight
    implicitWidth: Math.max(implicitHeight, figure.implicitWidth + Theme.space1 * 2)

    radius: height / 2
    color: Theme.accent

    Num {
        id: figure

        anchors.centerIn: parent

        text: String(root.count)
        color: Theme.onAccent

        font.weight: Font.Medium
    }
}
