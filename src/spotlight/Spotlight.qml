pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

// Spotlight, one instance per monitor: a field floating over the middle of
// the screen, and under it everything that can be started from the keyboard
// — the applications the session knows about, the notch's own pages, and
// the two safe ways out of the session.
//
// A pane of its own rather than a page of the notch. It is opened from a
// keybind, a hundred times a day, and it is where the eye already is: a
// little above the middle of the screen, not up at the edge. Blank, it is
// the field and the few things that get used most; typing narrows
// everything down to what fits, best first, under the headings Spotlight
// sorts by — the top hit on its own, larger, then the applications, then
// the shell's own pages. The arrows step through the list without leaving
// the field, Return opens what the step has reached, and a click opens a
// row directly. Escape clears the field, and on a blank field puts it away;
// so does a click anywhere else.
//
// The pane is frosted: its ground is not quite opaque, and on hyprland a
// layer rule on its namespace has the compositor blur what is behind it —
//
//     hl.layer_rule({ name = "spotlight-blur", match = { namespace = "^shell-spotlight$" }, blur = true, ignore_alpha = 0.5 })
//
// — so the shadow around it, which is fainter than that, stays sharp.
//
// Like the notch, the window covers the whole screen and never changes
// size: it is masked down to nothing while the pane is put away, and to the
// whole screen while it is out, to hear the click that dismisses it.
PanelWindow {
    id: root

    required property var modelData

    property bool open: false

    // a page of the notch was picked: the shell root turns this monitor's
    // notch to it, since the pane has no page of its own to show it on
    signal panelRequested(string name)

    function toggle(): void {
        root.open = !root.open;
    }

    // Out, with `text` already typed into the field.
    function search(text: string): void {
        root.open = true;
        searchField.text = text;
    }

    // Starts over each time it comes out: blank, with the caret in the field
    // and the step back at the top.
    onOpenChanged: {
        if (!root.open)
            return;

        searchField.clear();
        searchField.take();
        root.selected = 0;
        list.positionViewAtBeginning();
    }

    screen: root.modelData

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusiveZone: 0
    color: "transparent"

    // what a compositor rule picks this surface out by — see above
    WlrLayershell.namespace: "shell-spotlight"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Region {
        id: everywhere

        item: outside
    }

    Region {
        id: nowhere
    }

    mask: root.open ? everywhere : nowhere

    // ── what is on offer ──────────────────────────────────────────────────
    //
    // One shape for every row, whatever it does when it is picked: a name,
    // the line under it, the words it can be found by, and a mark — the
    // application's own icon when it has one, a glyph on a disc otherwise.

    // the notch's own pages, and the two session marks that are safe to
    // press once; restart and shut down want their second press, and stay
    // on the notch's home page where they get it
    readonly property var commands: [
        {
            key: "panel:notifications",
            title: "Notifications",
            caption: "Notch",
            about: "notification centre",
            icon: Icons.bell,
            panel: "notifications"
        },
        {
            key: "panel:audio",
            title: "Sound",
            caption: "Notch",
            about: "audio volume output input microphone speaker",
            icon: Icons.volumeHigh,
            panel: "audio"
        },
        {
            key: "panel:bluetooth",
            title: "Bluetooth",
            caption: "Notch",
            about: "devices pair connect",
            icon: Icons.bluetooth,
            panel: "bluetooth"
        },
        {
            key: "panel:network",
            title: "Network",
            caption: "Notch",
            about: "wifi ethernet vpn address",
            icon: Icons.ethernet,
            panel: "network"
        },
        {
            key: "panel:resources",
            title: "System",
            caption: "Notch",
            about: "cpu memory disk resources",
            icon: Icons.gauge,
            panel: "resources"
        },
        {
            key: "session:lock",
            title: "Lock",
            caption: "Session",
            about: "lock screen",
            icon: Icons.lock,
            run: () => Power.lock()
        },
        {
            key: "session:suspend",
            title: "Sleep",
            caption: "Session",
            about: "suspend",
            icon: Icons.sleep,
            run: () => Power.suspend()
        }
    ]

    // The applications, wrapped once per change of the set rather than once
    // per keystroke. `about` is everything an entry says about itself that
    // is not its name.
    readonly property var apps: Apps.entries.map(entry => ({
                key: entry.id,
                title: entry.name,
                caption: entry.genericName || entry.comment,
                about: [entry.genericName, entry.comment, ...(entry.keywords ?? [])].join(" "),
                icon: Icons.app,
                image: entry.icon ? Quickshell.iconPath(entry.icon, true) : "",
                entry
            }))

    readonly property var items: [...root.commands, ...root.apps]

    readonly property var tokens: Apps.tokens(searchField.text)

    // what fits the query, best first; blank, everything, used first
    readonly property var results: {
        const ranked = [];
        for (const item of root.items) {
            const fit = root.tokens.length === 0 ? 1 : Apps.match(item.title, item.about, root.tokens);
            if (fit === 0)
                continue;

            ranked.push({
                item,
                fit,
                weight: Apps.weight(item.key)
            });
        }

        ranked.sort((a, b) => b.fit - a.fit || b.weight - a.weight || a.item.title.localeCompare(b.item.title));
        return ranked.map(r => r.item);
    }

    // What is drawn, in the order the step walks it, each row with the
    // heading it is filed under. Blank, the few things that get used most;
    // with a query, the best fit on its own as the top hit, then the rest of
    // the applications, then the rest of the shell's own. Keyed by heading
    // and item, so a row that is still there from one keystroke to the next
    // is the same row, its icon already loaded.
    readonly property var rows: {
        const row = (item, group, hit) => ({
                    key: `${group}:${item.key}`,
                    item,
                    group,
                    hit
                });

        if (root.tokens.length === 0)
            return root.results.filter(item => Apps.weight(item.key) > 0).slice(0, Theme.spotlightRecents).map(item => row(item, "Recents", false));

        if (root.results.length === 0)
            return [];

        const [top, ...rest] = root.results;
        return [row(top, "Top Hit", true), ...rest.filter(item => item.entry).map(item => row(item, "Applications", false)), ...rest.filter(item => !item.entry).map(item => row(item, "Shell", false))];
    }

    // ── picking ───────────────────────────────────────────────────────────

    // the row Return opens; back to the top whenever the list changes under
    // it, since the best fit is always the first
    property int selected: 0

    onRowsChanged: {
        root.selected = 0;
        list.positionViewAtBeginning();
    }

    function step(delta: int): void {
        if (root.rows.length === 0)
            return;

        root.selected = Math.max(0, Math.min(root.rows.length - 1, root.selected + delta));
        list.positionViewAtIndex(root.selected, ListView.Contain);
    }

    // Do what the row does, once the pane is on its way out: an application
    // is launched, a page of the notch is opened on this monitor, a way out
    // of the session is taken.
    function activate(item: var): void {
        if (!item)
            return;

        root.open = false;

        if (item.entry) {
            Apps.launch(item.entry);
            return;
        }

        Apps.use(item.key);
        if (item.panel)
            root.panelRequested(item.panel);
        else
            item.run();
    }

    // ── everywhere else ───────────────────────────────────────────────────

    // A click anywhere but the pane puts it away; one on a part of the pane
    // that does nothing is swallowed. Declared ahead of the pane, and so
    // behind it.
    MouseArea {
        id: outside

        anchors.fill: parent

        enabled: root.open
        acceptedButtons: Qt.AllButtons

        onPressed: event => {
            const p = outside.mapToItem(pane, event.x, event.y);
            if (p.x < 0 || p.y < 0 || p.x >= pane.width || p.y >= pane.height)
                root.open = false;
        }
    }

    // ── the pane ──────────────────────────────────────────────────────────

    // Out, 1; put away, 0. It comes up out of a size a little smaller than
    // its own and fades in as it does, and goes the same way back, on a
    // spring, so a keybind pressed twice in a row turns it round where it is.
    Spring {
        id: appearing

        to: root.open ? 1 : 0
    }

    // ...and it grows and shrinks with what it lists the way the notch does
    // with the page it is showing. Put away, it takes its new size at once.
    Spring {
        id: deepening

        leaf: "windows"
        enabled: pane.visible
        to: column.implicitHeight
    }

    Shadow {
        target: pane
        radius: pane.radius

        opacity: pane.opacity
        scale: pane.scale
    }

    ClippingRectangle {
        id: pane

        anchors.horizontalCenter: parent.horizontalCenter

        // whole pixels, or the text on it shimmers as it grows
        y: Math.round(root.height * Theme.spotlightTop)
        width: Theme.spotlightWidth
        height: Math.round(deepening.value)

        radius: Theme.radiusLarge
        color: Theme.glass

        border.width: 1
        border.color: Theme.glassEdge

        opacity: Math.max(0, Math.min(1, appearing.value))
        scale: Theme.spotlightScale + (1 - Theme.spotlightScale) * appearing.value
        visible: opacity > 0

        ColumnLayout {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 0

            SearchField {
                id: searchField

                Layout.fillWidth: true

                bare: true
                pixelSize: Theme.fontSearch
                padding: Theme.space4
                placeholder: "Spotlight Search"

                onCancelled: root.open = false
                onAccepted: root.activate(root.rows[root.selected]?.item)
                onStepped: delta => root.step(delta)
            }

            // the hairline under the field, once there is something under it
            Rectangle {
                Layout.fillWidth: true

                visible: list.visible || nothing.visible

                implicitHeight: 1
                color: Theme.glassEdge
            }

            Empty {
                id: nothing

                Layout.margins: Theme.space4

                visible: root.tokens.length > 0 && root.rows.length === 0

                text: `No results for “${searchField.text.trim()}”`
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.margins: Theme.spotlightPadding
                // a few rows, and never further down than the screen goes
                Layout.preferredHeight: Math.min(list.contentHeight, Theme.spotlightListHeight, root.height - pane.y - searchField.height - Theme.space8)

                visible: root.rows.length > 0

                clip: true
                boundsBehavior: Flickable.StopAtBounds

                model: ScriptModel {
                    values: root.rows
                    objectProp: "key"
                }

                delegate: ColumnLayout {
                    id: entry

                    required property var modelData
                    required property int index

                    // the first row filed under a heading carries it
                    readonly property bool heads: entry.index === 0 || root.rows[entry.index - 1]?.group !== entry.modelData.group

                    width: ListView.view.width

                    spacing: 0

                    Caption {
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.rowPadding
                        Layout.topMargin: entry.index === 0 ? Theme.space1 : Theme.space3
                        Layout.bottomMargin: Theme.space1

                        visible: entry.heads

                        text: entry.modelData.group
                        color: Theme.textDim

                        font.weight: Font.DemiBold
                    }

                    Result {
                        Layout.fillWidth: true

                        item: entry.modelData.item
                        hit: entry.modelData.hit
                        selected: entry.index === root.selected

                        onClicked: root.activate(entry.modelData.item)
                    }
                }
            }
        }
    }
}
