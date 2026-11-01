pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What has been copied, from cliphist, and the way back onto the clipboard.
//
// The shell keeps no history of its own: cliphist is the daemon that sits on
// `wl-paste --watch` and writes down everything that is copied, and this
// asks it for the list when there is someone to show it to rather than
// following along. Each entry is what cliphist previews it as, one line
// with its whitespace folded; picking one has cliphist decode it whole and
// hands that to `wl-copy`, so a picture comes back a picture and a page of
// text comes back the page.
//
// The list says plainly when there is nothing to show: cliphist missing is
// one thing, and cliphist with nothing written down yet — or its daemon
// never having run — is another.
Singleton {
    id: root

    // newest first: { id, text, image }, where `text` is what the list
    // shows and `image` whether the entry is a picture
    property var entries: []

    // whether there is a cliphist to ask at all; assumed until it is asked
    property bool available: true

    // asked, and not answered yet
    readonly property bool loading: list.running

    // Ask again. The list is only as fresh as the last time it was asked
    // for, so this runs every time it is about to be shown.
    function refresh(): void {
        if (!list.running)
            list.running = true;
    }

    // Put an entry back on the clipboard, whole. The id goes to the shell
    // as an argument rather than as part of the line it runs.
    function copy(entry: var): void {
        if (!entry)
            return;

        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", entry.id]);
    }

    // ...and put something the shell worked out there itself, an answer
    // from the calculator say
    function copyText(text: string): void {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    // What a picture is called in the list. cliphist previews anything it
    // can read as an image as `[[ binary data 12 KiB png 1920x1080 ]]`,
    // which is a description written for a terminal; the list says
    // "PNG image, 1920×1080 · 12 KiB".
    function label(preview: string): var {
        const binary = /^\[\[ binary data (.+?) ([a-z0-9]+) (\d+)x(\d+) \]\]$/i.exec(preview);
        if (!binary)
            return {
                text: preview,
                image: false
            };

        return {
            text: `${binary[2].toUpperCase()} image, ${binary[3]}×${binary[4]} · ${binary[1]}`,
            image: true
        };
    }

    // one entry per line, its id and its preview split by a tab
    function parse(text: string): void {
        const found = [];
        for (const line of text.split("\n")) {
            const entry = /^(\d+)\t(.*)$/.exec(line);
            if (!entry)
                continue;

            const shown = root.label(entry[2]);
            found.push({
                id: entry[1],
                text: shown.text,
                image: shown.image
            });
        }
        root.entries = found;
    }

    Process {
        id: list

        // 127 is what a shell says for a command it could not find, and the
        // one answer that means there is no history to be had
        command: ["sh", "-c", "command -v cliphist >/dev/null || exit 127; exec cliphist -preview-width 200 list"]

        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }

        onExited: exitCode => {
            root.available = exitCode !== 127;
            // anything else is cliphist with nothing written down yet
            if (exitCode !== 0)
                root.entries = [];
        }
    }
}
