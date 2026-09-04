pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
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

    // What is left for the list once the panel has had its half of the
    // screen: the header is a fixed height, so the list gets the rest and
    // scrolls once it runs out.
    readonly property int listMax: Math.max(Theme.listMinHeight, root.notch.bodyMaxHeight - header.height - root.spacing)

    spacing: Theme.expandedSpacing

    PanelHeader {
        id: header

        Layout.fillWidth: true

        title: "Notifications"

        onBack: root.notch.panel = "home"

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
                    ColorAnimation {
                        duration: Theme.fadeDuration
                    }
                }
            }
        }
    }

    Sans {
        Layout.fillWidth: true
        Layout.margins: Theme.cardPadding

        visible: Notifs.count === 0

        text: "No notifications."
        color: Theme.textDim
    }

    // The list, and the bar that turns up beside it once there is more in it
    // than fits. The two are siblings so the bar holds still while the list
    // scrolls under it.
    Item {
        Layout.fillWidth: true
        // grows with the list until the notch would be half the screen tall
        Layout.preferredHeight: Math.min(list.contentHeight, root.listMax)

        visible: Notifs.count > 0

        ListView {
            id: list

            anchors.fill: parent
            // the gutter the bar needs, taken from the list only when there
            // is going to be a bar in it
            anchors.rightMargin: bar.overflowing ? bar.width : 0

            clip: true
            spacing: Theme.listSpacing
            boundsBehavior: Flickable.StopAtBounds

            // Diffed against what is already there, so a row arriving or
            // leaving touches only itself, and one being updated in place
            // is the same row with new words on it.
            model: ScriptModel {
                values: Notifs.kept
            }

            delegate: NotifRow {
                required property var modelData

                width: ListView.view.width
                record: modelData
            }

            // a new one arriving while the panel is open fades in at the top
            // and the rest make room for it
            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.fadeDuration
                }
            }

            displaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: Theme.expandDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.expandCurve
                }
            }

            // ...and one leaving fades where it is, and the rest close over
            // the gap once it has gone rather than up through it
            remove: Transition {
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: Theme.fadeDuration
                }
            }

            removeDisplaced: Transition {
                SequentialAnimation {
                    PauseAnimation {
                        duration: Theme.fadeDuration
                    }

                    NumberAnimation {
                        property: "y"
                        duration: Theme.expandDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.expandCurve
                    }
                }
            }
        }

        ScrollBar {
            id: bar

            flickable: list
        }
    }
}
