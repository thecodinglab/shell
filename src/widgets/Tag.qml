import QtQuick
import qs.theme

// The little rounded word at the end of a row: connected, pair, a2dp.
Rectangle {
    id: root

    property alias text: label.text
    property bool accented: false

    implicitWidth: label.implicitWidth + Theme.px(8) * 2
    implicitHeight: label.implicitHeight + Theme.px(3) * 2

    radius: Theme.tagRadius
    color: root.accented ? Theme.accentSurface : Theme.surfaceHover

    Text {
        id: label

        anchors.centerIn: parent

        color: root.accented ? Theme.accent : Theme.textMuted

        font.family: Theme.monoFamily
        font.pixelSize: Theme.fontSmall
    }
}
