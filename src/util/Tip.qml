pragma Singleton

import QtQuick
import Quickshell

// The one tooltip: which control is asking for it, and what it says.
//
// A tooltip has to be drawn over everything on the sheet, and a child of the
// control it names is drawn under whatever comes after that control on the
// page. So a control does not draw its own; it registers here, and the notch
// draws the one tooltip above its whole page — see `Tooltip`.
Singleton {
    id: root

    // the control, and the words
    property Item item: null
    property string text: ""

    function show(item: Item, text: string): void {
        root.item = item;
        root.text = text;
    }

    // only the control that put it up may take it down: a pointer crossing
    // from one control to the next has already been claimed by the next
    function hide(item: Item): void {
        if (root.item !== item)
            return;

        root.item = null;
        root.text = "";
    }
}
