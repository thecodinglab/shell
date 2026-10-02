pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.widgets

// The launcher: a field, and under it everything that can be started from
// the keyboard — the applications the session knows about, and the notch's
// own pages and the two safe ways out of it, which used to need a launcher
// of their own.
//
// It is the one page opened from a keybind rather than from the home page,
// so it has no title and no way back: the field is its head, the caret is
// already in it, and escape puts the notch away. Typing narrows the list,
// the arrows step through it without leaving the field, and Return picks
// whatever the step has reached; a click picks a row directly. The row
// Return would pick is lit the way a row under the pointer is.
//
// Blank, the list is everything, with what gets used at the top and the
// rest in alphabetical order under it; the tally that decides which is
// which is Apps'.
ColumnLayout {
    id: root

    required property var notch

    // ── what is on offer ──────────────────────────────────────────────────
    //
    // One shape for every row, whatever it does when it is picked: a name,
    // the line under it, the words it can be found by, and a mark — the
    // application's own icon when it has one, a glyph on a disc otherwise.

    // the notch's own pages, and the two session marks that are safe to
    // press once; restart and shut down want their second press, and stay
    // on the home page where they get it
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
    // per keystroke, so the list can tell a row that is still there from one
    // that is new. `about` is everything an entry says about itself that is
    // not its name.
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

    // what fits the query, best first; blank, everything, used first
    readonly property var results: {
        const tokens = Apps.tokens(search.text);

        const ranked = [];
        for (const item of root.items) {
            const fit = tokens.length === 0 ? 1 : Apps.match(item.title, item.about, tokens);
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

    // ── picking ───────────────────────────────────────────────────────────

    // the row Return picks; back to the top whenever the list changes under
    // it, since the best fit is always the first
    property int selected: 0

    onResultsChanged: root.selected = 0

    function step(delta: int): void {
        if (root.results.length === 0)
            return;

        root.selected = Math.max(0, Math.min(root.results.length - 1, root.selected + delta));
        list.reveal(root.selected);
    }

    // Do what the row does. An application, or a way out of the session,
    // folds the notch first: it is about to be somewhere else. A page of the
    // notch is reached the way it is from the home page, and escape from it
    // returns there rather than here.
    function activate(item: var): void {
        if (!item)
            return;

        if (item.entry) {
            root.notch.expanded = false;
            Apps.launch(item.entry);
            return;
        }

        Apps.use(item.key);
        if (item.panel) {
            root.notch.panel = item.panel;
        } else {
            root.notch.expanded = false;
            item.run();
        }
    }

    spacing: Theme.stackSpacing

    // The field borrows the keyboard while the panel is up; hand it back on
    // the way out so escape still steps out of the notch.
    Component.onDestruction: root.notch.takeKeys()

    SearchField {
        id: search

        Layout.fillWidth: true

        placeholder: "Search"

        // escape on a blank field puts the notch away: this page was not
        // reached from anywhere it could step back to
        onCancelled: root.notch.dismiss()
        onAccepted: root.activate(root.results[root.selected])
        onStepped: delta => root.step(delta)

        Component.onCompleted: search.take()
    }

    // The notch takes the keyboard for itself each time it unfolds. This
    // page is usually built after that and takes it back as it is built,
    // but a launcher toggled shut and open again before the notch has
    // finished folding is the same page still standing, and starts over
    // here: blank, with the caret in the field.
    Connections {
        target: root.notch

        function onExpandedChanged(): void {
            if (!root.notch.expanded)
                return;

            search.clear();
            search.take();
        }
    }

    Empty {
        visible: root.results.length === 0

        text: root.items.length === 0 ? "No applications" : `Nothing called “${search.text.trim()}”`
    }

    ScrollList {
        id: list

        Layout.fillWidth: true
        // the rows reach out past the page margin so their ground wraps the
        // icon rather than starting at it
        Layout.leftMargin: -Theme.rowPadding
        Layout.rightMargin: -Theme.rowPadding

        visible: root.results.length > 0

        // a few rows, not a page of them — and never more than the notch's
        // half of the screen has room for
        maxHeight: Math.min(Theme.launcherHeight, Math.max(Theme.listMinHeight, root.notch.bodyMaxHeight - search.height - root.spacing))

        values: root.results

        delegate: ListRow {
            id: row

            required property var modelData
            required property int index

            readonly property bool current: row.index === root.selected

            width: ListView.view.width

            rule: row.index < root.results.length - 1
            ruleInset: Theme.discSizeSmall + Theme.rowSpacing
            selected: row.current

            Accessible.name: row.modelData.title

            onClicked: root.activate(row.modelData)

            // the mark: the application's own icon at its own shape, or a
            // glyph on a disc for anything that has none
            Item {
                Layout.alignment: Qt.AlignVCenter

                implicitWidth: Theme.discSizeSmall
                implicitHeight: Theme.discSizeSmall

                IconImage {
                    anchors.fill: parent

                    visible: (row.modelData.image ?? "") !== ""

                    source: row.modelData.image ?? ""
                    implicitSize: Theme.discSizeSmall
                    asynchronous: true
                }

                IconDisc {
                    anchors.fill: parent

                    visible: (row.modelData.image ?? "") === ""

                    icon: row.modelData.icon
                    size: Theme.discSizeSmall
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                title: row.modelData.title
                caption: row.modelData.caption ?? ""
                captionColor: row.hovered ? Theme.textMuted : Theme.textDim
            }

            // on the row Return would pick, the key that does it
            Glyph {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: Theme.space1

                visible: row.current

                text: Icons.enter
                color: Theme.textFaint

                Layout.preferredWidth: implicitWidth
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}
