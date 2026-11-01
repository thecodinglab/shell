pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

// Spotlight, one instance per monitor: a field floating over the middle of
// the screen, and under it everything that can be reached from the keyboard
// — the applications the session knows about, the windows already open, the
// notch's own pages, the two safe ways out of the session, the answer to a
// sum, and what has been copied.
//
// A pane of its own rather than a page of the notch. It is opened from a
// keybind, a hundred times a day, and it is where the eye already is: a
// little above the middle of the screen, not up at the edge. Blank, it is
// the field and the few things that get used most; typing narrows
// everything down to what fits, best first, under the headings Spotlight
// sorts by — the top hit on its own, larger, then the applications, then
// the windows, then the shell's own pages. The arrows step through the list
// without leaving the field, Return opens what the step has reached, and a
// click opens a row directly. Escape clears the field, and on a blank field
// puts it away; so does a click anywhere else.
//
// A sum typed into the field is worked out as it is typed, and its answer
// is the top hit, with the search carrying on underneath as if it were not
// there. The clipboard history is a place in the pane rather than a thing
// to start: picked from the shell's rows, it turns the same field and list
// over to what has been copied, newest first and narrowed by what is typed,
// and Escape on a blank field comes back out of it instead of putting the
// pane away.
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

    // What the field and the list are about: "" for the search, and
    // "clipboard" for the clipboard history.
    property string mode: ""

    // a page of the notch was picked: the shell root turns this monitor's
    // notch to it, since the pane has no page of its own to show it on
    signal panelRequested(string name)

    function toggle(): void {
        root.open = !root.open;
    }

    // Out, with `text` already typed into the field.
    function search(text: string): void {
        root.open = true;
        root.mode = "";
        searchField.text = text;
    }

    // Out, on the clipboard history.
    function clipboard(): void {
        root.open = true;
        root.mode = "clipboard";
    }

    // Starts over each time it comes out: blank, on the search, with the
    // caret in the field and the step back at the top. The windows are
    // taken as they are now — see below.
    onOpenChanged: {
        if (!root.open)
            return;

        root.mode = "";
        searchField.clear();
        searchField.take();
        root.selected = 0;
        list.positionViewAtBeginning();
        root.takeWindows();
    }

    // Each way in starts blank, and the clipboard history is asked for
    // afresh every time it is shown, since it is not followed in between.
    onModeChanged: {
        searchField.clear();
        if (root.mode === "clipboard")
            Clipboard.refresh();
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

    // the notch's own pages, the clipboard history, and the two session
    // marks that are safe to press once; restart and shut down want their
    // second press, and stay on the notch's home page where they get it
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
            key: "mode:clipboard",
            title: "Clipboard",
            caption: "History",
            about: "clipboard history copied paste cliphist",
            icon: Icons.clipboard,
            mode: "clipboard"
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

    // The windows open right now, found by their titles first and then by
    // the application they belong to. Taken once each time the pane comes
    // out rather than followed, so a window whose title keeps changing — a
    // terminal running a clock, a player naming the track — does not pull
    // the list out from under the step while it is being walked.
    property var windows: []

    function takeWindows(): void {
        // the class rides on the last answer to `hyprctl clients`; this
        // asks for a new one for the next time, and the wayland handle
        // knows it in the meantime
        Hyprland.refreshToplevels();

        root.windows = Hyprland.toplevels.values.map(toplevel => {
            const appId = toplevel.wayland?.appId || toplevel.lastIpcObject?.class || "";
            const entry = appId ? DesktopEntries.heuristicLookup(appId) : null;
            const app = entry?.name || appId;
            const title = toplevel.title || app;
            const workspace = toplevel.workspace?.name ?? "";

            return {
                key: `window:${toplevel.address}`,
                title,
                caption: workspace ? `${app} — workspace ${workspace}` : app,
                about: [appId, app].join(" "),
                label: `${title}, ${app} window`,
                icon: Icons.window,
                image: entry?.icon ? Quickshell.iconPath(entry.icon, true) : "",
                address: toplevel.address
            };
        });
    }

    readonly property var items: [...root.commands, ...root.apps, ...root.windows]

    readonly property var tokens: Apps.tokens(searchField.text)

    // A sum typed into the field, and its answer. Null for anything that is
    // not one, which is nearly everything, and which takes next to nothing
    // to find out — see Calc.
    readonly property var answer: {
        if (root.mode !== "" || root.tokens.length === 0)
            return null;

        const value = Calc.evaluate(searchField.text);
        if (value === null)
            return null;

        const result = Calc.format(value);
        return {
            key: "calculator",
            title: result,
            caption: "Calculator",
            label: `${searchField.text.trim()} is ${result}`,
            icon: Icons.calculator,
            answer: result
        };
    }

    // what fits the query, best first; blank, everything, used first
    readonly property var results: {
        if (root.mode !== "")
            return [];

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

    // The clipboard history, narrowed to the entries with every word of the
    // query somewhere in them. Newest first whatever is typed, rather than
    // best fit first: what was copied a moment ago is nearly always what is
    // wanted back.
    readonly property var history: {
        if (root.mode !== "clipboard")
            return [];

        return Clipboard.entries.filter(entry => {
            const text = entry.text.toLowerCase();
            return root.tokens.every(token => text.includes(token));
        }).map(entry => ({
                    key: `clipboard:${entry.id}`,
                    title: entry.text,
                    icon: entry.image ? Icons.image : Icons.clipboard,
                    clip: entry
                }));
    }

    // What is drawn, in the order the step walks it, each row with the
    // heading it is filed under. Blank, the few things that get used most;
    // with a query, the best fit on its own as the top hit — or the answer,
    // when the query is a sum — then the rest of the applications, then the
    // windows, then the rest of the shell's own. On the clipboard history,
    // the history. Keyed by heading and item, so a row that is still there
    // from one keystroke to the next is the same row, its icon already
    // loaded.
    readonly property var rows: {
        const row = (item, group, hit) => ({
                    key: `${group}:${item.key}`,
                    item,
                    group,
                    hit
                });

        if (root.mode === "clipboard")
            return root.history.map(item => row(item, "Clipboard", false));

        if (root.tokens.length === 0)
            return root.results.filter(item => Apps.weight(item.key) > 0).slice(0, Theme.spotlightRecents).map(item => row(item, "Recents", false));

        const [top, ...rest] = root.answer ? [root.answer, ...root.results] : root.results;
        if (!top)
            return [];

        return [row(top, "Top Hit", true), ...rest.filter(item => item.entry).map(item => row(item, "Applications", false)), ...rest.filter(item => item.address).map(item => row(item, "Windows", false)), ...rest.filter(item => !item.entry && !item.address).map(item => row(item, "Shell", false))];
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
    // is launched, a window is brought forward, a page of the notch is
    // opened on this monitor, a way out of the session is taken, and an
    // answer or an entry of the history goes onto the clipboard. The
    // clipboard history itself is the one row that keeps the pane out,
    // because it is somewhere in the pane rather than something done.
    function activate(item: var): void {
        if (!item)
            return;

        if (item.mode) {
            Apps.use(item.key);
            root.mode = item.mode;
            return;
        }

        root.open = false;

        if (item.answer) {
            Clipboard.copyText(item.answer);
            return;
        }

        if (item.clip) {
            Clipboard.copy(item.clip);
            return;
        }

        if (item.address) {
            root.focusWindow(item.address);
            return;
        }

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

    // Bring a window forward, wherever it is: hyprland switches to its
    // workspace, and its monitor, on the way. Windows are not counted the
    // way applications are, because an address only lasts as long as its
    // window does. The dispatch is written in whichever language the
    // compositor's config is.
    function focusWindow(address: string): void {
        const hex = address.startsWith("0x") ? address : `0x${address}`;
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ window = "address:${hex}" })` : `focuswindow address:${hex}`);
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
                placeholder: root.mode === "clipboard" ? "Search Clipboard" : "Spotlight Search"

                // escape on a blank field steps back out of the history
                // first, and only then puts the pane away
                onCancelled: {
                    if (root.mode !== "")
                        root.mode = "";
                    else
                        root.open = false;
                }
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

                visible: root.rows.length === 0 && (root.tokens.length > 0 || root.mode === "clipboard")
                busy: root.mode === "clipboard" && Clipboard.loading && Clipboard.entries.length === 0

                // the history says why it is empty before it says that
                // nothing fits
                text: {
                    if (root.mode === "clipboard") {
                        if (!Clipboard.available)
                            return "Clipboard history needs cliphist, which is not installed";
                        if (Clipboard.entries.length === 0)
                            return Clipboard.loading ? "Reading the clipboard history" : "Nothing has been copied yet";
                    }
                    return `No results for “${searchField.text.trim()}”`;
                }
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
