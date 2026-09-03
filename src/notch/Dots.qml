pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.theme

// This monitor's workspaces, as dots. The active one stretches into a bar
// instead of growing, so the row keeps its rhythm.
//
// Every workspace bound to this monitor by a rule gets a dot whether it is
// open or not, so the row is the same width no matter what is running and
// there is always something to click to get somewhere. A monitor with no
// rules falls back to the first Config.workspaceCount workspaces, minus any
// that are open on another monitor.
Row {
    id: root

    required property var screen

    readonly property var monitor: Hyprland.monitorFor(root.screen)
    readonly property var open: Hyprland.workspaces.values.filter(w => w.id > 0)
    readonly property var here: root.open.filter(w => w.monitor === root.monitor)
    readonly property var bound: Workspaces.idsFor(root.monitor?.name ?? "")

    readonly property var ids: {
        const ids = new Set(root.bound);
        for (const w of root.here)
            ids.add(w.id);

        if (root.bound.length === 0) {
            const elsewhere = new Set(root.open.filter(w => w.monitor !== root.monitor).map(w => w.id));
            for (let i = 1; i <= Config.workspaceCount; i++)
                if (!elsewhere.has(i))
                    ids.add(i);
        }

        return [...ids].sort((a, b) => a - b);
    }

    spacing: Theme.dotSpacing

    Repeater {
        model: root.ids

        Rectangle {
            id: dot

            required property int modelData

            readonly property int workspaceId: dot.modelData
            readonly property var workspace: root.here.find(w => w.id === dot.workspaceId) ?? null
            // the one this monitor is showing, focused or not: every notch
            // marks its own, not just the one the pointer is on
            readonly property bool active: dot.workspace?.active ?? false

            implicitWidth: dot.active ? Theme.dotActiveWidth : Theme.dotSize
            implicitHeight: Theme.dotSize

            radius: height / 2

            color: {
                if (dot.workspace?.urgent)
                    return Theme.urgent;
                if (dot.active)
                    return Theme.accent;
                return dot.workspace ? Theme.dotOccupied : Theme.dotEmpty;
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Theme.fadeDuration
                    easing.type: Theme.expandEasing
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Theme.fadeDuration
                }
            }

            MouseArea {
                anchors.fill: parent
                // a 6px target is not a target; reach out to the midpoint of
                // the gap on either side and well past the dot vertically
                anchors.leftMargin: -Theme.dotSpacing / 2
                anchors.rightMargin: -Theme.dotSpacing / 2
                anchors.topMargin: -Theme.px(8)
                anchors.bottomMargin: -Theme.px(8)

                cursorShape: Qt.PointingHandCursor

                // a workspace that is not open yet is created by the switch,
                // on this monitor, because it is bound here
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${dot.workspaceId} })`)
            }
        }
    }
}
