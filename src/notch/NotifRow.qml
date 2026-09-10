import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.util
import qs.widgets

// One notification in the panel: the toast it was, laid out as a row in a
// list, with when it arrived where the toast had no need of one, and a
// cross that turns up under the pointer to get rid of it.
//
// A click on the row does what the toast would have done — what the
// notification was for, or the application it came from — and leaves the row
// where it is. Only the cross takes it away: opening something is not the
// same as being done with it.
ListRow {
    id: root

    required property var record

    ruleInset: Theme.discSizeSmall + Theme.rowSpacing

    onClicked: Notifs.open(root.record)

    NotifContent {
        Layout.fillWidth: true

        title: root.record?.summary || root.record?.appName || ""
        // who, and when; the clock is read against the same one the rest of
        // the shell keeps, so the column ticks over together
        meta: [root.record?.appName ?? "", Fmt.ago(root.record?.time ?? 0, Time.now.getTime())].filter(part => part).join(", ")
        body: root.record?.body ?? ""
        image: root.record?.image ?? ""
        icon: root.record?.appIcon || root.record?.desktopEntry || ""
        urgent: root.record?.urgent ?? false
        discSize: Theme.discSizeSmall
    }

    // Only there while the pointer is on the row, or on the cross itself, or
    // the keyboard has reached either; the space for it is always kept, so
    // the text beside it does not shift when it appears.
    held: cross.hovered

    IconButton {
        id: cross

        Layout.alignment: Qt.AlignTop
        Layout.topMargin: -Theme.space1

        icon: Icons.close
        label: "Dismiss"
        pixelSize: Theme.fontSmall

        opacity: root.hovered || root.activeFocus || cross.activeFocus ? 1 : 0

        onClicked: Notifs.forget(root.record)
    }
}
