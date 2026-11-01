pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.widgets

// What the dot on the pill is about: the microphone, the camera and the
// screen, whichever of them is in use, and which applications are using it.
//
// A line each, laid out the way a tile is but without its ground, because
// there is nothing here to press: the disc, lit, since the thing behind it is
// in use, the same as a tile's; what it is; and under that who has it. It is
// only on the page while something is in use, and then it is the first thing
// under the clock, where the eye lands coming down from the pill.
ColumnLayout {
    id: root

    visible: Privacy.active

    spacing: Theme.stackSpacing

    Use {
        visible: Privacy.microphone

        icon: Icons.microphone
        title: "Microphone"
        apps: Privacy.microphoneApps
    }

    Use {
        visible: Privacy.camera

        icon: Icons.camera
        title: "Camera"
        apps: Privacy.cameraApps
    }

    Use {
        visible: Privacy.screen

        icon: Icons.screenShare
        title: "Screen sharing"
        apps: Privacy.screenApps
    }

    component Use: RowLayout {
        id: use

        property string icon: ""
        property string title: ""
        property var apps: []

        Layout.fillWidth: true

        spacing: Theme.rowSpacing

        IconDisc {
            Layout.alignment: Qt.AlignVCenter

            icon: use.icon
            on: true
            size: Theme.discSizeSmall
        }

        // A screen being shared is there before anyone has picked it up, and
        // then there is nobody to name yet.
        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            title: use.title
            caption: use.apps.join(", ") || "In use"
        }
    }
}
