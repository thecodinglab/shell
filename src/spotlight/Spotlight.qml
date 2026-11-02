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
// Two pieces of glass rather than a page of the notch. It is opened from a
// keybind, a hundred times a day, and it is where the eye already is: a
// little above the middle of the screen, not up at the edge. At its head is
// a capsule that is only the field, and it never moves; under it, a gap
// away, hangs a sheet of results whenever there is anything to list. Blank,
// it is the field and the few things that get used most; typing narrows
// everything down to what fits, best first, under the headings Spotlight
// sorts by — the top hit on its own, larger, then the applications, then
// the windows, then the notch's pages, then the few things the shell does.
// The arrows step through the list without leaving the field, Return opens
// what the step has reached, and a click opens a row directly. Escape
// clears the field, and on a blank field puts it away; so does a click
// anywhere else.
//
// A sum typed into the field is worked out as it is typed, and its answer
// is the top hit, with the search carrying on underneath as if it were not
// there. The clipboard history is a place in Spotlight rather than a thing
// to start: picked from the shell's rows, it turns the same field and list
// over to what has been copied, newest first and narrowed by what is typed.
// The field says so with a token at its head, the way a search narrowed to
// one kind of thing says what it is narrowed to, and Escape or Backspace on
// a blank field comes back out of it instead of putting it away.
//
// Both pieces are glass: their ground is not quite opaque, and on hyprland
// a layer rule on its namespace has the compositor blur what is behind them —
//
//     hl.layer_rule({ name = "spotlight-blur", match = { namespace = "^shell-spotlight$" }, blur = true, ignore_alpha = 0.5 })
//
// — so the shadow around them, which is fainter than that, stays sharp.
//
// Like the notch, the window covers the whole screen and never changes
// size: it is masked down to nothing while Spotlight is put away, and to
// the whole screen while it is out, to hear the click that dismisses it.
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
        root.wiping = false;
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
        root.wiping = false;
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
    // thing's own icon when it has one, a glyph on a disc otherwise.

    // An icon from the session's theme, by its freedesktop name, or nothing
    // when the theme has none and the row falls back to its glyph.
    function themed(name: string): string {
        return Quickshell.iconPath(name, true);
    }

    // the notch's own pages, the clipboard history, and the two session
    // marks that are safe to press once; restart and shut down want their
    // second press, and stay on the notch's home page where they get it
    readonly property var commands: [
        {
            key: "panel:notifications",
            title: "Notifications",
            caption: "Opens in the notch",
            about: "notification centre",
            icon: Icons.bell,
            image: root.themed("preferences-desktop-notification"),
            panel: "notifications"
        },
        {
            key: "panel:audio",
            title: "Sound",
            caption: "Opens in the notch",
            about: "audio volume output input microphone speaker",
            icon: Icons.volumeHigh,
            image: root.themed("audio-volume-high"),
            panel: "audio"
        },
        {
            key: "panel:bluetooth",
            title: "Bluetooth",
            caption: "Opens in the notch",
            about: "devices pair connect",
            icon: Icons.bluetooth,
            image: root.themed("bluetooth"),
            panel: "bluetooth"
        },
        {
            key: "panel:network",
            title: "Network",
            caption: "Opens in the notch",
            about: "wifi ethernet vpn address",
            icon: Icons.ethernet,
            image: root.themed("network-wired"),
            panel: "network"
        },
        {
            key: "panel:resources",
            title: "System",
            caption: "Opens in the notch",
            about: "cpu memory disk resources",
            icon: Icons.gauge,
            image: root.themed("utilities-system-monitor"),
            panel: "resources"
        },
        {
            key: "mode:clipboard",
            title: "Clipboard",
            caption: "History",
            about: "clipboard history copied paste cliphist",
            icon: Icons.clipboard,
            image: root.themed("edit-paste"),
            mode: "clipboard"
        },
        {
            key: "session:lock",
            title: "Lock",
            caption: "Session",
            about: "lock screen",
            icon: Icons.lock,
            image: root.themed("system-lock-screen"),
            run: () => Power.lock()
        },
        {
            key: "session:suspend",
            title: "Sleep",
            caption: "Session",
            about: "suspend",
            icon: Icons.sleep,
            image: root.themed("system-suspend"),
            run: () => Power.suspend()
        }
    ]

    // The applications, wrapped once per change of the set rather than once
    // per keystroke. The line under the name is the kind of thing it is —
    // "Web Browser" — rather than its blurb, which can run to a sentence;
    // `about` is everything an entry says about itself that is not its name.
    readonly property var apps: Apps.entries.map(entry => ({
                key: entry.id,
                title: entry.name,
                caption: entry.genericName || "Application",
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
            // the sum the answer is to, as a calculator shows it over the
            // answer, rather than the name of what worked it out
            caption: `${searchField.text.trim()} =`,
            label: `${searchField.text.trim()} is ${result}`,
            icon: Icons.calculator,
            image: root.themed("accessories-calculator"),
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

    // The way to forget the whole history, at its head while nothing is
    // typed: a history that is shown should be one that can be cleared. It
    // wants a second press — see `wiping` — because nothing brings it back.
    readonly property var wipe: ({
            key: "clipboard:wipe",
            title: "Clear clipboard history",
            icon: Icons.erase,
            image: root.themed("edit-clear-history"),
            wipe: true
        })

    // What is drawn, in the order the step walks it, each row with the
    // heading it is filed under. Blank, the few things that get used most;
    // with a query, the best fit on its own as the top hit — or the answer,
    // when the query is a sum — then the rest of the applications, then the
    // windows, then the notch's pages, then the rest of what the shell does.
    // On the clipboard history, the history, under the way to clear it.
    // Keyed by heading and item, so a row that is still there from one
    // keystroke to the next is the same row, its icon already loaded.
    readonly property var rows: {
        const row = (item, group, hit) => ({
                    key: `${group}:${item.key}`,
                    item,
                    group,
                    hit
                });

        if (root.mode === "clipboard") {
            const wipe = root.tokens.length === 0 && root.history.length > 0 ? [root.wipe] : [];
            return [...wipe, ...root.history].map(item => row(item, "Clipboard", false));
        }

        if (root.tokens.length === 0)
            return root.results.filter(item => Apps.weight(item.key) > 0).slice(0, Theme.spotlightRecents).map(item => row(item, "Recents", false));

        const [top, ...rest] = root.answer ? [root.answer, ...root.results] : root.results;
        if (!top)
            return [];

        return [row(top, "Top Hit", true), ...rest.filter(item => item.entry).map(item => row(item, "Applications", false)), ...rest.filter(item => item.address).map(item => row(item, "Windows", false)), ...rest.filter(item => item.panel).map(item => row(item, "Notch", false)), ...rest.filter(item => !item.entry && !item.address && !item.panel).map(item => row(item, "Actions", false))];
    }

    // A query, or the history, with nothing to list, which the sheet comes
    // out to say rather than staying away. Here rather than read off the
    // line that says it, which sits in the sheet and so is only ever
    // visible while the sheet already is.
    readonly property bool listsNothing: root.rows.length === 0 && (root.tokens.length > 0 || root.mode === "clipboard")

    // ── picking ───────────────────────────────────────────────────────────

    // The row Return opens. Back to the top whenever the list changes under
    // it, since the best fit is always the first; on the history that is the
    // newest entry rather than the row that clears them all, which is there
    // to be reached for and not landed on.
    property int selected: 0

    // Where the step lands in `rows`. Worked out from the rows it is handed
    // rather than bound to them, because it is asked for the moment they
    // change, before anything else bound to them has caught up.
    function firstOf(rows: var): int {
        return rows[0]?.item.wipe && rows.length > 1 ? 1 : 0;
    }

    // ...except after an entry has been deleted from the history, when the
    // step stays where it was, on the entry that came up into its place
    property int kept: -1

    onRowsChanged: {
        const first = root.firstOf(root.rows);
        if (root.kept >= 0) {
            root.selected = Math.max(first, Math.min(root.rows.length - 1, root.kept));
            root.kept = -1;
            list.positionViewAtIndex(root.selected, ListView.Contain);
            return;
        }

        root.selected = first;
        list.positionViewAtBeginning();
    }

    function step(delta: int): void {
        if (root.rows.length === 0)
            return;

        root.selected = Math.max(0, Math.min(root.rows.length - 1, root.selected + delta));
        list.positionViewAtIndex(root.selected, ListView.Contain);
    }

    // The clear row has been pressed once, and the next press within the
    // hold empties the history; left alone, it lets the first one go, the
    // way restart and shut down do on the notch.
    property bool wiping: false

    Timer {
        interval: Theme.confirmHold
        running: root.wiping

        onTriggered: root.wiping = false
    }

    // What a row is called for now: the clear row, pressed once, asks
    // whether to go through with it, the way a session mark on the notch
    // does. A question rather than a key to press, since the first press
    // may as well have been a click.
    function titleOf(item: var): string {
        return item.wipe && root.wiping ? "Clear clipboard history?" : item.title;
    }

    // Do what the row does, once Spotlight is on its way out: an application
    // is launched, a window is brought forward, a page of the notch is
    // opened on this monitor, a way out of the session is taken, and an
    // answer or an entry of the history goes onto the clipboard. The
    // clipboard history itself, and the clearing of it, keep Spotlight out,
    // because they are somewhere in it rather than something done.
    function activate(item: var): void {
        if (!item)
            return;

        if (item.mode) {
            Apps.use(item.key);
            root.mode = item.mode;
            return;
        }

        if (item.wipe) {
            if (root.wiping)
                Clipboard.wipe();
            root.wiping = !root.wiping;
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

    // Forget the entry of the history the step is on, for something that
    // should never have been written down — a password, say. Delete does it
    // once the caret is at the end of what is typed, where it has nothing of
    // the field's left to delete.
    function forget(): void {
        const item = root.rows[root.selected]?.item;
        if (root.mode !== "clipboard" || !item?.clip)
            return;

        root.kept = root.selected;
        Clipboard.remove(item.clip);
    }

    // One step back: out of the history first, and only then away.
    function back(): void {
        if (root.mode !== "")
            root.mode = "";
        else
            root.open = false;
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

    // A click anywhere but the field or the sheet puts Spotlight away; one
    // on a part of either that does nothing is swallowed. Declared ahead of
    // them, and so behind them.
    MouseArea {
        id: outside

        anchors.fill: parent

        enabled: root.open
        acceptedButtons: Qt.AllButtons

        onPressed: event => {
            const within = item => {
                const p = outside.mapToItem(item, event.x, event.y);
                return item.visible && p.x >= 0 && p.y >= 0 && p.x < item.width && p.y < item.height;
            };
            if (!within(field) && !within(results))
                root.open = false;
        }
    }

    // ── the field and the sheet ───────────────────────────────────────────

    // Out, 1; put away, 0. Both pieces come up out of a size a little
    // smaller than their own and fade in as they do, and go the same way
    // back, on a spring, so a keybind pressed twice in a row turns them
    // round where they are.
    Spring {
        id: appearing

        to: root.open ? 1 : 0
    }

    // ...and the sheet grows and shrinks with what it lists, on the quick
    // spring a window moves on rather than the one the notch unfolds on: it
    // changes with nearly every key, and is read rather than watched. Hidden,
    // it takes its new size at once, and it comes out at the size it is.
    Spring {
        id: deepening

        leaf: "windowsMove"
        visible: results.visible
        to: column.implicitHeight
    }

    // The two pieces, scaled together about the field, so the field holds
    // still and the sheet keeps its gap under it as they come and go.
    Item {
        id: stage

        anchors.horizontalCenter: parent.horizontalCenter

        // whole pixels, or the text on it shimmers as it grows
        y: Math.round(root.height * Theme.spotlightTop)
        width: Theme.spotlightWidth
        height: field.height

        opacity: Math.max(0, Math.min(1, appearing.value))
        scale: Theme.spotlightScale + (1 - Theme.spotlightScale) * appearing.value
        visible: opacity > 0

        // Escape from whatever else the keys have reached — the clear
        // button — clears the field the way it would from inside it, and
        // puts the caret back there, or steps back out once it is blank.
        // The field answers it for itself.
        Keys.onEscapePressed: event => {
            if (searchField.empty) {
                root.back();
            } else {
                searchField.clear();
                searchField.take();
            }
            event.accepted = true;
        }

        Shadow {
            target: field
            radius: field.radius
        }

        // The field: a capsule of glass that is the search and nothing
        // else, and stays where it is whatever comes and goes under it.
        Rectangle {
            id: field

            objectName: Theme.paneTag

            width: parent.width
            height: fieldRow.implicitHeight

            radius: height / 2
            color: Theme.pane.glass

            RowLayout {
                id: fieldRow

                anchors.fill: parent

                spacing: 0

                SearchField {
                    id: searchField

                    Layout.fillWidth: true

                    bare: true
                    pixelSize: Theme.fontSearch
                    padding: Theme.space4
                    placeholder: root.mode === "clipboard" ? "Search Clipboard" : "Spotlight Search"
                    // what is being searched, when it is not everything
                    scope: root.mode === "clipboard" ? "Clipboard" : ""
                    // the row Return would open, read out after the field
                    selectionLabel: {
                        const item = root.rows[root.selected]?.item;
                        return item ? item.label ?? root.titleOf(item) : "";
                    }

                    // escape on a blank field steps back out of the history
                    // first, and only then puts Spotlight away; backspace
                    // only steps back out
                    onCancelled: root.back()
                    onBackedOut: {
                        if (root.mode !== "")
                            root.mode = "";
                    }
                    onDeleted: root.forget()
                    onAccepted: root.activate(root.rows[root.selected]?.item)
                    onStepped: delta => root.step(delta)
                }

                // A bare field has no clear button of its own, since it is
                // usually the whole of its pane; this one is a capsule of
                // its own, so it gets one, a full target centred in the
                // capsule's round end.
                IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: Math.round((field.height - Theme.actionSize) / 2)

                    visible: !searchField.empty

                    icon: Icons.close
                    label: "Clear"
                    size: Theme.actionSize
                    pixelSize: Theme.fontTitle

                    onClicked: {
                        searchField.clear();
                        searchField.take();
                    }
                }
            }

            // the rim of the glass, over everything else on it
            Rim {
                target: field
                radius: field.radius
            }
        }

        Shadow {
            target: results
            radius: results.radius

            visible: results.visible
        }

        // The sheet of results, hanging a gap under the field whenever there
        // is something to list or to say there is nothing. Its rows sit a
        // little in from its edge, with corners that follow its own.
        ClippingRectangle {
            id: results

            objectName: Theme.paneTag

            y: field.height + Theme.spotlightGap
            width: parent.width
            height: Math.round(deepening.value)

            visible: root.rows.length > 0 || root.listsNothing

            radius: Theme.radiusLarge
            color: Theme.pane.glass

            // Out at the size it is: its rows and its height arrive in the
            // same moment, but not always in the same order.
            onVisibleChanged: {
                if (results.visible)
                    Qt.callLater(deepening.jump);
            }

            ColumnLayout {
                id: column

                anchors.left: parent.left
                anchors.right: parent.right

                spacing: 0

                Empty {
                    id: nothing

                    // The line in the middle of a sheet of its own, on the
                    // edge the rows start on, with air enough over and under
                    // it that the sheet is still a sheet: one line's height
                    // with its corners would be a capsule, a second field
                    // under the first. The top is set again over the one a
                    // panel gives it, under a heading.
                    Layout.margins: Theme.space4
                    Layout.topMargin: Theme.space6
                    Layout.bottomMargin: Theme.space6

                    visible: root.listsNothing
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
                    Layout.preferredHeight: Math.min(list.contentHeight, Theme.spotlightListHeight, root.height - stage.y - results.y - Theme.spotlightPadding * 2 - Theme.space8)

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
                            color: Theme.pane.textDim

                            font.weight: Font.DemiBold
                        }

                        Result {
                            Layout.fillWidth: true

                            item: entry.modelData.item
                            title: root.titleOf(entry.modelData.item)
                            danger: entry.modelData.item.wipe === true && root.wiping
                            hit: entry.modelData.hit
                            selected: entry.index === root.selected

                            onClicked: root.activate(entry.modelData.item)
                        }
                    }
                }
            }
        }

        // ...and the sheet's, beside it rather than in it, since the sheet
        // clips what it holds
        Rim {
            target: results
            radius: results.radius

            visible: results.visible
        }
    }
}
