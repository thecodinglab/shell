pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The applications the session can launch, how a query is matched against
// them, and a tally of what gets launched.
//
// The entries are the desktop files quickshell already keeps track of, with
// the ones that ask not to be listed left out. The matching is by name
// first — the start of it, then the start of a word in it, then anywhere in
// it — and only then by what an entry says about itself, so typing "spot"
// puts Spotify ahead of anything that merely mentions it. The tally breaks
// ties by how often, and how recently, each thing has been picked from the
// launcher, and is written to `$XDG_STATE_HOME/shell/launches.json` as it
// changes. It is keyed by string, so the launcher can count the notch's own
// pages alongside the applications.
Singleton {
    id: root

    // every application that wants to be seen, in no particular order
    readonly property var entries: DesktopEntries.applications.values.filter(entry => !entry.noDisplay)

    // key -> { count, last }: what has been picked from the launcher so far
    property var launches: ({})

    // ── matching ──────────────────────────────────────────────────────────

    // a query as the words it is made of, lowercased; nothing for a blank
    function tokens(query: string): var {
        return (query ?? "").trim().toLowerCase().split(/\s+/).filter(t => t.length > 0);
    }

    // How well one token fits a thing called `name` that describes itself
    // as `about`: the start of the name outranks the start of a word in it,
    // which outranks the name containing it anywhere, which outranks a word
    // of the description. Nought is no fit at all.
    function fit(name: string, about: string, token: string): real {
        const n = name.toLowerCase();
        if (n.startsWith(token))
            return 4;
        if (n.split(/[\s\-_.\/]+/).some(word => word.startsWith(token)))
            return 3;
        if (n.includes(token))
            return 2;
        if (about.toLowerCase().split(/[\s\-_.\/,;]+/).some(word => word.startsWith(token)))
            return 1;
        return 0;
    }

    // ...and for a whole query: every token has to land somewhere, and the
    // query fits as well as its worst token does.
    function match(name: string, about: string, tokens: var): real {
        let worst = Infinity;
        for (const token of tokens) {
            const f = root.fit(name, about, token);
            if (f === 0)
                return 0;
            worst = Math.min(worst, f);
        }
        return worst;
    }

    // How much a thing gets used, weighted toward lately: a pick a fortnight
    // ago counts for half of one today, so something used every day last
    // month and not since drifts back down the list on its own.
    function weight(key: string): real {
        const record = root.launches[key];
        if (!record)
            return 0;

        const age = Math.max(0, Date.now() - record.last) / (24 * 60 * 60 * 1000);
        return record.count * Math.pow(0.5, age / 14);
    }

    // ── launching ─────────────────────────────────────────────────────────

    // Run it, and count it. An entry that wants a terminal is given the
    // configured one; without one it is run as it is, which for most of
    // those means nothing you can see happens.
    function launch(entry: DesktopEntry): void {
        if (!entry)
            return;

        if (entry.runInTerminal && Config.terminal !== "") {
            Quickshell.execDetached({
                command: [Config.terminal, "-e", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        } else {
            entry.execute();
        }

        root.use(entry.id);
    }

    // one more pick of `key`, now
    function use(key: string): void {
        const record = root.launches[key] ?? {
            count: 0,
            last: 0
        };
        root.launches = Object.assign({}, root.launches, {
            [key]: {
                count: record.count + 1,
                last: Date.now()
            }
        });
        root.save();
    }

    // ── the tally ─────────────────────────────────────────────────────────
    //
    // Kept under the state directory rather than next to the config, which
    // lives in the store and changes path on every rebuild.

    readonly property string storePath: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/shell/launches.json`

    function save(): void {
        flush.restart();
    }

    Timer {
        id: flush

        interval: 250

        onTriggered: store.setText(JSON.stringify(root.launches))
    }

    // Read once, at startup; from then on this is the only writer.
    function restore(text: string): void {
        let parsed = {};
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            console.warn(`${root.storePath} is not valid json, starting over: ${e}`);
        }
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed))
            parsed = {};

        const restored = {};
        for (const [key, record] of Object.entries(parsed)) {
            if (typeof record?.count !== "number" || typeof record?.last !== "number")
                continue;
            restored[key] = {
                count: record.count,
                last: record.last
            };
        }

        // anything picked before the file was read counts on top
        for (const [key, record] of Object.entries(root.launches)) {
            const known = restored[key];
            restored[key] = {
                count: (known?.count ?? 0) + record.count,
                last: Math.max(known?.last ?? 0, record.last)
            };
        }

        root.launches = restored;
    }

    FileView {
        id: store

        path: root.storePath
        atomicWrites: true
        // the shell is the only thing that writes this file
        watchChanges: false
        // a missing file is the first run
        printErrors: false

        onLoaded: root.restore(store.text())
    }
}
