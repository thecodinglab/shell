import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.util
import qs.widgets

// One notification in the panel: the toast it was, laid out as a row in a
// list, with when it arrived where the toast had no need of one, and the
// cross that puts it away standing in that place under the pointer, the way
// it does on the toast.
//
// A click on the row does what the toast would have done — what the
// notification was for, or the application it came from — and leaves the row
// where it is. Only the cross takes it away: opening something is not the
// same as being done with it. While the notification is still open behind
// the row, what it offered to do is on the row as it was on the toast, and
// doing one of them deals with it there as it would have there.
ListRow {
    id: root

    required property var record

    ruleInset: Theme.discSizeSmall + Theme.rowSpacing

    // read out as what it is and who sent it, then what it says
    Accessible.name: [root.record?.urgent ? "Critical" : "", root.record?.summary, root.record?.appName].filter(part => part).join(", ")
    Accessible.description: root.record?.body ?? ""

    onClicked: Notifs.open(root.record)

    // the pointer on one of its buttons, which takes the hover from the row
    held: content.pointed

    NotifContent {
        id: content

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
        badgeSize: Theme.rowBadgeSize

        actions: (root.record?.notification?.actions ?? []).filter(a => a.identifier !== "default").slice(0, 3)
        live: !!root.record?.notification

        // Only there while the pointer is on the row or the keyboard has
        // reached it or the cross itself; its place is always kept, so the
        // line it is on does not shift when it appears.
        dismissable: true
        offered: root.hovered || root.activeFocus || content.crossFocused

        onActed: action => Notifs.act(root.record.notification, action)
        onDismissed: Notifs.forget(root.record)
    }
}
