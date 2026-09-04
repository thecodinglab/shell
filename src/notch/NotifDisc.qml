import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme

// The mark at the head of a notification: the sender's own icon on a disc,
// or a bell on the accent's when it has none. An urgent one sits on the
// red instead, whatever it carries.
Rectangle {
    id: root

    // an image the notification came with, if it did — a path, or the
    // server's own image provider url while the notification is still up
    property string image: ""
    // the sender's icon, by name
    property string icon: ""
    property bool urgent: false
    property int size: Theme.discSize

    readonly property string source: {
        if (root.image)
            return root.image;
        return root.icon ? Quickshell.iconPath(root.icon, true) : "";
    }

    implicitWidth: root.size
    implicitHeight: root.size

    radius: width / 2
    color: {
        if (root.urgent)
            return Theme.urgentSurface;
        return root.source !== "" ? Theme.surfaceRaised : Theme.accentSurface;
    }

    IconImage {
        anchors.centerIn: parent

        visible: root.source !== ""

        source: root.source
        implicitSize: Math.round(root.size * 0.6)
        asynchronous: true
    }

    Text {
        anchors.centerIn: parent

        visible: root.source === ""

        text: Icons.bell
        color: root.urgent ? Theme.urgent : Theme.accent

        font.family: Theme.monoFamily
        font.pixelSize: Math.round(root.size * 0.4)
    }
}
