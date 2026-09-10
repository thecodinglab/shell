import QtQuick
import qs.theme
import qs.util

// The one tooltip, drawn over the whole page by the notch that owns it.
//
// A control that wants one registers with Tip; this finds out whether that
// control is on this notch's sheet — there is one notch a monitor — and if so
// puts the words under it, or over it when there is no room under, and never
// past the edge of the sheet.
//
// What it says and where it sits are set when it is shown and held from
// then on, so a bubble on its way out neither loses its words nor moves.
Item {
    id: root

    readonly property Item target: Tip.item
    readonly property bool shown: Tip.text !== "" && root.owns(root.target)

    // whether a control is on this notch's sheet
    function owns(item: Item): bool {
        while (item) {
            if (item === root.parent)
                return true;
            item = item.parent;
        }
        return false;
    }

    anchors.fill: parent

    // over everything the page draws
    z: 100

    function place(): void {
        // read off Tip directly: the words arrive in the same call that set
        // the control, and the bindings above may not have caught up yet
        const item = Tip.item;
        if (!item || Tip.text === "" || !root.owns(item))
            return;

        words.text = Tip.text;

        // under the middle of the control, unless there is no room under
        const at = item.mapToItem(root, item.width / 2, item.height);
        const below = at.y + Theme.space1 + bubble.height <= root.height - Theme.space2;

        bubble.x = Math.max(Theme.space2, Math.min(root.width - bubble.width - Theme.space2, at.x - bubble.width / 2));
        bubble.y = below ? at.y + Theme.space1 : at.y - item.height - Theme.space1 - bubble.height;
    }

    // the words land after the control, so this is the moment both are set
    Connections {
        target: Tip

        function onTextChanged(): void {
            root.place();
        }
    }

    Rectangle {
        id: bubble

        implicitWidth: words.implicitWidth + Theme.tooltipPadding * 2
        implicitHeight: words.implicitHeight + Theme.space1 * 2

        radius: Theme.radiusSmall
        color: Theme.fill

        opacity: root.shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Fade {}
        }

        Caption {
            id: words

            anchors.centerIn: parent

            color: Theme.onFill
        }
    }
}
