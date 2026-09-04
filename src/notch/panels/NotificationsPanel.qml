pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.widgets
import qs.notch

// Everything that has come in and not been dealt with, newest at the top —
// the notification centre, in the sense a laptop has one.
//
// A toast that ran out of time lands here; one that was clicked or put away
// by hand does not, because that was dealing with it. Each row leaves the
// same two ways, by its cross or by being opened, and the whole list can be
// cleared from the header. What is left is gone on its own after a day.
ColumnLayout {
    id: root

    required property var notch

    spacing: Theme.expandedSpacing

    PanelHeader {
        id: header

        Layout.fillWidth: true

        notch: root.notch
        title: "Notifications"

        // the one action that belongs to the list rather than to a row on
        // it; a word rather than a glyph, since a cross up here would read
        // as closing the panel
        ListRow {
            id: clearAll

            visible: Notifs.count > 0

            flat: true
            padding: Theme.px(6)

            onClicked: Notifs.clear()

            Caption {
                text: "Clear all"
                color: clearAll.hovered ? Theme.textBody : Theme.textMuted

                Behavior on color {
                    ColorFade {}
                }
            }
        }
    }

    Empty {
        visible: Notifs.count === 0

        text: "No notifications."
    }

    ScrollList {
        Layout.fillWidth: true

        visible: Notifs.count > 0

        // what is left once the panel has had its half of the screen: the
        // header is a fixed height, so the list gets the rest and scrolls
        // once it runs out
        maxHeight: Math.max(Theme.listMinHeight, root.notch.bodyMaxHeight - header.height - root.spacing)

        values: Notifs.kept

        delegate: NotifRow {
            required property var modelData

            width: ListView.view.width
            record: modelData
        }
    }
}
