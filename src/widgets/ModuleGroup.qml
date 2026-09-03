import QtQuick
import qs.theme

// One of the three rounded pills the bar is made of.
Rectangle {
    id: root

    default property alias content: row.data

    // the workspace pill sits flush against its buttons, the other two
    // inset their text
    property int padding: Theme.groupPadding

    implicitWidth: row.implicitWidth + root.padding * 2
    implicitHeight: Theme.groupHeight

    radius: Theme.groupRadius
    color: Theme.background

    Row {
        id: row

        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding

        spacing: Theme.moduleSpacing
    }
}
