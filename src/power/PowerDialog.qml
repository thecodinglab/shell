pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.util
import qs.widgets

// The ways out of the session, in a pane of their own: what the power key on
// a mac brings up. One for the whole shell, out on whichever monitor it was
// asked for on — the one whose notch the power mark was pressed on, or the
// one with focus for a keybind.
//
// It is the password pane's glass at the width of four choices: the power
// mark at its head, the question under it — "Shut down this computer now?"
// — then Lock, Sleep, Restart and Shut down, a disc each with its name
// under it, and Cancel across the foot. The pane is the confirmation, so
// every choice acts on one press: there is no second press to ask for, and
// nothing that ends the session is ever a click away from somewhere else.
// Escape, Cancel, or a click anywhere off the pane puts it away untouched.
//
// Return presses only what the keyboard is on; nothing is pressed for it
// by default, so a Return meant for something else never ends the session.
// Tab walks the choices and Cancel, and the arrows step along the choices.
//
// While it is out it has the keyboard, and the whole screen, so the click
// that puts it away does not land on a window as well.
PanelWindow {
    id: root

    property bool open: false

    // it has come out, for the shell root to put away whatever else had
    // the keyboard
    signal opened

    // Out on `screen`: placed before it is mapped, so it never comes out on
    // one monitor and moves to another; caught on its way out, it turns
    // round where it is.
    function show(screen: var): void {
        if (!root.visible)
            root.screen = screen;
        root.open = true;
        // Onto nothing in particular, every time: the scope would otherwise
        // hand the keyboard back to whatever had it when the pane was last
        // put away, and a Return would press Shut down if that was it.
        nothing.forceActiveFocus();
        root.opened();
    }

    function cancel(): void {
        root.open = false;
    }

    // Put away first, then done: a lock screen or a suspend arriving while
    // the pane is still out would come back to it.
    function press(action: string): void {
        root.open = false;
        switch (action) {
        case "lock":
            Power.lock();
            break;
        case "suspend":
            Power.suspend();
            break;
        case "reboot":
            Power.reboot();
            break;
        case "poweroff":
            Power.poweroff();
            break;
        }
    }

    visible: root.open || pane.visible

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusiveZone: 0
    color: "transparent"

    // what a compositor rule picks this surface out by, as the password
    // pane's `shell-polkit` is
    WlrLayershell.namespace: "shell-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Region {
        id: everywhere

        item: outside
    }

    Region {
        id: nowhere
    }

    mask: root.open ? everywhere : nowhere

    // ── everywhere else ───────────────────────────────────────────────────

    // A click off the pane puts it away; one on a part of it that does
    // nothing is swallowed. Declared ahead of the pane, and so behind it.
    MouseArea {
        id: outside

        anchors.fill: parent

        enabled: root.open
        acceptedButtons: Qt.AllButtons

        onPressed: event => {
            const p = outside.mapToItem(pane, event.x, event.y);
            if (p.x < 0 || p.y < 0 || p.x >= pane.width || p.y >= pane.height)
                root.cancel();
        }
    }

    // ── the pane ──────────────────────────────────────────────────────────

    // Out, 1; put away, 0, on a spring the way the password pane comes and
    // goes.
    Spring {
        id: appearing

        to: root.open ? 1 : 0
    }

    Shadow {
        target: pane
        radius: pane.radius

        opacity: pane.opacity
        scale: pane.scale
    }

    ClippingRectangle {
        id: pane

        // glass, and everything on it drawn for glass
        objectName: Theme.paneTag

        // whole pixels, or the text on it shimmers as it moves
        x: Math.round((root.width - pane.width) / 2)
        y: Math.round(root.height * Theme.polkitTop)
        width: Theme.powerWidth
        height: column.implicitHeight + Theme.pagePadding * 2

        // concentric with Cancel, a page margin in
        radius: Theme.polkitRadius
        color: Theme.pane.glass

        opacity: Math.max(0, Math.min(1, appearing.value))
        scale: Theme.polkitScale + (1 - Theme.polkitScale) * appearing.value
        visible: opacity > 0

        Accessible.role: Accessible.Dialog
        Accessible.name: "Shut down this computer now?"

        // Every key lands here once the control that has the focus has
        // passed on it: the first one turns the ring on, and escape puts
        // the pane away.
        FocusScope {
            id: scope

            anchors.fill: parent

            focus: true

            Keys.onPressed: Nav.key()
            Keys.onEscapePressed: root.cancel()

            // where the keyboard starts: on none of the choices, so Return
            // does nothing until one has been reached; Tab goes from here
            // to the first
            Item {
                id: nothing

                focus: true
            }

            ColumnLayout {
                id: column

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.pagePadding

                spacing: 0

                IconDisc {
                    Layout.alignment: Qt.AlignHCenter

                    icon: Icons.power
                    size: Theme.polkitIconSize
                }

                Sans {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space3

                    text: "Shut down this computer now?"

                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }

                // ── the four ways out ─────────────────────────────────────

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space4
                    // the choices' hover grounds reach out to the pane's
                    // margins, so the discs stay on its grid
                    Layout.leftMargin: -Theme.rowPadding
                    Layout.rightMargin: -Theme.rowPadding

                    spacing: 0

                    Repeater {
                        id: choices

                        model: [
                            {
                                action: "lock",
                                icon: Icons.lock,
                                label: "Lock"
                            },
                            {
                                action: "suspend",
                                icon: Icons.sleep,
                                label: "Sleep"
                            },
                            {
                                action: "reboot",
                                icon: Icons.restart,
                                label: "Restart"
                            },
                            {
                                action: "poweroff",
                                icon: Icons.power,
                                label: "Shut down"
                            }
                        ]

                        ListRow {
                            id: choice

                            required property var modelData
                            required property int index

                            // an equal quarter each, taken from the pane
                            // rather than from the width of the word under
                            // the disc
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1

                            Accessible.name: choice.modelData.label

                            onClicked: root.press(choice.modelData.action)

                            // the arrows step along the row, and stop at
                            // its ends
                            Keys.onLeftPressed: (choices.itemAt(choice.index - 1) as Item)?.forceActiveFocus()
                            Keys.onRightPressed: (choices.itemAt(choice.index + 1) as Item)?.forceActiveFocus()

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                spacing: Theme.space2

                                IconDisc {
                                    Layout.alignment: Qt.AlignHCenter

                                    icon: choice.modelData.icon
                                    size: Theme.powerDiscSize
                                    pressed: choice.pressed
                                    iconColor: choice.hovered ? Theme.pane.text : Theme.pane.textMuted
                                }

                                Caption {
                                    Layout.fillWidth: true

                                    text: choice.modelData.label
                                    color: choice.hovered ? Theme.pane.text : Theme.pane.textMuted

                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space4
                    implicitHeight: Theme.polkitFieldHeight

                    text: "Cancel"

                    onClicked: root.cancel()
                }
            }
        }
    }

    // the rim of the glass, over it rather than round it, and so beside it:
    // the pane clips what it holds
    Rim {
        target: pane
        radius: pane.radius

        opacity: pane.opacity
        scale: pane.scale
        visible: pane.visible
    }
}
