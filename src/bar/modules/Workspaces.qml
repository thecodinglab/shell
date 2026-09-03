import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme

// Workspaces of the monitor this bar is on, sorted by id, with the focused
// one highlighted. Special workspaces stay hidden, as they did in waybar.
Row {
    id: root

    required property var screen

    readonly property var monitor: Hyprland.monitorFor(root.screen)

    readonly property var workspaces: Hyprland.workspaces.values.filter(w => w.monitor === root.monitor && w.id >= 0).sort((a, b) => a.id - b.id)

    spacing: 0

    Repeater {
        model: root.workspaces

        Rectangle {
            id: button

            required property var modelData

            implicitWidth: Math.max(Theme.workspaceMinWidth, label.implicitWidth + Theme.workspacePadding * 2)
            height: root.height

            radius: Theme.groupRadius
            color: {
                if (button.modelData.urgent)
                    return Theme.workspaceUrgent;
                if (button.modelData.focused)
                    return Theme.workspaceActive;
                return "transparent";
            }

            Text {
                id: label

                anchors.centerIn: parent

                text: button.modelData.name
                color: Theme.foreground

                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontPixelSize
                font.letterSpacing: Theme.letterSpacing
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch(`workspace ${button.modelData.id}`)
            }
        }
    }
}
