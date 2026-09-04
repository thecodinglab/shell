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
// The row itself is the other way of dealing with it: a click does what the
// toast would have done — what the notification was for, or the application
// it came from — and takes the row with it.
ListRow {
    id: root

    required property var record

    flat: true
    padding: Theme.rowPadding

    onClicked: Notifs.open(root.record)

    NotifDisc {
        Layout.alignment: Qt.AlignTop
        Layout.leftMargin: Theme.px(2)

        image: root.record?.image ?? ""
        icon: root.record?.appIcon || root.record?.desktopEntry || ""
        urgent: root.record?.urgent ?? false
        size: Theme.discSizeSmall
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        spacing: Theme.px(2)

        RowLayout {
            Layout.fillWidth: true

            spacing: Theme.rowSpacing

            Sans {
                Layout.fillWidth: true

                text: root.record?.summary || root.record?.appName || ""
                color: Theme.text

                font.weight: Font.Medium
            }

            // who, and when; the clock is read against the same one the
            // rest of the shell keeps, so the column ticks over together
            Caption {
                text: [root.record?.appName ?? "", Fmt.ago(root.record?.time ?? 0, Time.now.getTime())].filter(part => part).join(" · ")
                color: Theme.textFaint
            }
        }

        Sans {
            Layout.fillWidth: true

            visible: text !== ""

            text: root.record?.body ?? ""
            color: Theme.textMuted

            // the server advertises markup support, so bodies arrive with
            // it in them
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            maximumLineCount: 3
            lineHeight: 1.35
        }
    }

    // Always there, so the text beside it does not shift when it appears;
    // only lit while the pointer is on the row. Read off a handler rather
    // than the row's own mouse area, so it stays lit while the pointer is
    // on the cross itself, which has a mouse area of its own.
    HoverHandler {
        id: hover
    }

    IconButton {
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: -Theme.px(3)

        icon: Icons.close
        size: Theme.px(22)
        pixelSize: Theme.fontSmall

        opacity: hover.hovered ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.fadeDuration
            }
        }

        onClicked: Notifs.forget(root.record)
    }
}
