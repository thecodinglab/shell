pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.theme
import qs.util
import qs.widgets

// This monitor's workspaces, as dots. The active one stretches into a bar
// instead of growing, so the row keeps its rhythm, and one asking for
// attention into a shorter one, so it is told by its shape as well as by
// the red.
//
// Every workspace bound to this monitor by a rule gets a dot whether it is
// open or not, so the row is the same width no matter what is running and
// there is always something to click to get somewhere. A monitor with no
// rules falls back to the first Config.workspaceCount workspaces, minus any
// that are open on another monitor.
Row {
    id: root

    required property var screen
    // How far above and below the row each dot's target reaches: to the
    // edges of whatever the row sits in, so a pointer anywhere in that band
    // over a dot is on it. The default is the room the home page leaves
    // around it; the pill is taller, and says so.
    property int reach: Theme.space2

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
            readonly property bool urgent: dot.workspace?.urgent ?? false

            // a workspace that is not open yet is created by the switch,
            // on this monitor, because it is bound here
            function go(): void {
                Hyprland.dispatch(`hl.dsp.focus({ workspace = ${dot.workspaceId} })`);
            }

            implicitWidth: Math.round(stretch.value)
            implicitHeight: Theme.dotSize

            radius: height / 2

            // Here in the accent, and asking for attention in the red. One
            // that exists is filled, and one that does not exist yet is only
            // its outline: it is still somewhere to go, but nothing is there.
            color: {
                if (dot.urgent)
                    return Theme.bezel.urgent;
                if (dot.active)
                    return Theme.bezel.accent;
                return dot.workspace ? Theme.bezel.dotOccupied : Theme.clear(Theme.bezel.dotOccupied);
            }
            border.width: dot.workspace ? 0 : 1
            border.color: Theme.bezel.dotOccupied

            // switched away from before it has finished stretching, it
            // shrinks back from as far as it got
            Spring {
                id: stretch

                visible: dot.visible
                to: {
                    if (dot.active)
                        return Theme.dotActiveWidth;
                    return dot.urgent ? Theme.dotUrgentWidth : Theme.dotSize;
                }
            }

            Behavior on color {
                ColorFade {}
            }

            activeFocusOnTab: true

            Accessible.role: Accessible.Button
            Accessible.name: `Workspace ${dot.workspaceId}${dot.active ? ", current" : ""}${dot.urgent ? ", needs attention" : ""}`
            Accessible.onPressAction: dot.go()

            Keys.onPressed: event => {
                Nav.key();
                if (event.key !== Qt.Key_Space && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
                    return;

                dot.go();
                event.accepted = true;
            }

            // a dot is too small to hold a ring: it goes round the outside
            FocusRing {
                inset: -Theme.space1
                radius: height / 2
            }

            MouseArea {
                anchors.fill: parent
                // A dot is not a target. Each one reaches out to the midpoint
                // of the gap on either side, so the row is one strip of
                // targets with no dead space between them, and up and down
                // as far as `reach`.
                anchors.leftMargin: -Theme.dotSpacing / 2
                anchors.rightMargin: -Theme.dotSpacing / 2
                anchors.topMargin: -root.reach
                anchors.bottomMargin: -root.reach

                // the arrow, as over any control; the pointing hand is for links
                cursorShape: Qt.ArrowCursor

                onPressed: Nav.pointer()
                onClicked: dot.go()
            }
        }
    }
}
