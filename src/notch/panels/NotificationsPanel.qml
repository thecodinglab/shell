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

    // the room under the header, with what there is to say in the middle
    // of it: as much as it takes to say it, and any more the page has
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: empty.implicitHeight

        visible: Notifs.count === 0

        Empty {
            id: empty

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            centred: true

            text: "No notifications"
        }
    }

    ScrollList {
        Layout.fillWidth: true
        // the rows reach out past the page margin so their hover ground
        // wraps the mark rather than starting at it
        Layout.leftMargin: -Theme.rowPadding
        Layout.rightMargin: -Theme.rowPadding

        visible: Notifs.count > 0

        // the rest of the room under the header, scrolling once it runs out;
        // and any room left over, should rows go while the page is open
        Layout.fillHeight: true
        maxHeight: Math.max(Theme.listMinHeight, root.notch.pageRoom - header.height - root.spacing)

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
