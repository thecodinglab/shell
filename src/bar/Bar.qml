import QtQuick
import Quickshell
import qs.theme
import qs.widgets
import qs.bar.modules

// The bar, one instance per monitor.
PanelWindow {
    id: root

    required property var modelData

    screen: root.modelData

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    // the pills paint their own background, the gaps between them let the
    // wallpaper through
    color: "transparent"

    ModuleGroup {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.groupMargin

        padding: 0

        Workspaces {
            height: parent.height
            screen: root.modelData
        }
    }

    ModuleGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        Clock {}
    }

    ModuleGroup {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Theme.groupMargin

        DiskUsage {}
        Volume {}
        CpuUsage {}
        MemoryUsage {}
        NetworkStatus {}
    }
}
