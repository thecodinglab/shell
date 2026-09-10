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
// by hand does not, because that was dealing with it. A row opens what it
// is about when clicked and stays; its cross takes it away, and the whole
// list can be cleared from the header. What is left is gone on its own
// after a day.
ColumnLayout {
    id: root

    required property var notch

    spacing: Theme.stackSpacing

    PanelHeader {
        id: header

        Layout.fillWidth: true

        notch: root.notch
        title: "Notifications"

        // the one action that belongs to the list rather than to a row on
        // it; a word rather than a glyph, since a cross up here would read
        // as closing the panel
        Button {
            visible: Notifs.count > 0

            text: "Clear all"

            onClicked: Notifs.clear()
        }
    }

    Empty {
        visible: Notifs.count === 0

        text: "No notifications"
    }

    ScrollList {
        Layout.fillWidth: true
        // the rows reach out past the page margin so their hover ground
        // wraps the mark rather than starting at it
        Layout.leftMargin: -Theme.rowPadding
        Layout.rightMargin: -Theme.rowPadding

        visible: Notifs.count > 0

        // what is left once the panel has had its half of the screen: the
        // header is a fixed height, so the list gets the rest and scrolls
        // once it runs out
        maxHeight: Math.max(Theme.listMinHeight, root.notch.bodyMaxHeight - header.height - root.spacing)

        values: Notifs.kept

        delegate: NotifRow {
            required property var modelData
            required property int index

            width: ListView.view.width
            record: modelData
            rule: index < Notifs.count - 1
        }
    }
}
