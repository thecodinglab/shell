import QtQuick
import QtQuick.Layouts
import qs.theme

// The first row of a sub-panel: the way back, what you are looking at, and
// whatever that panel wants on the right.
RowLayout {
    id: root

    default property alias trailing: trailingRow.data

    property string title: ""

    signal back

    spacing: Theme.rowSpacing

    Text {
        Layout.alignment: Qt.AlignVCenter

        text: Icons.back
        color: back.containsMouse ? Theme.text : Theme.textDim

        font.family: Theme.monoFamily
        font.pixelSize: Theme.fontMeta

        MouseArea {
            id: back

            anchors.fill: parent
            anchors.margins: -Theme.px(6)

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: root.back()
        }
    }

    Text {
        Layout.fillWidth: true

        text: root.title
        color: Theme.text

        font.family: Theme.sansFamily
        font.pixelSize: Theme.fontTitle
        font.weight: Font.DemiBold
    }

    RowLayout {
        id: trailingRow

        Layout.alignment: Qt.AlignVCenter

        spacing: Theme.rowSpacing
    }
}
