import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.util
import qs.widgets

// The line a polkit prompt is answered on: a field on the raised ground,
// with the key at its head the way the magnifier heads a search, and the
// prompt the conversation asked with — "Password", most of the time — as
// the words in it until something is typed.
//
// What is typed is held by the field and by nothing else. Nothing reads or
// binds to it; `handOver()` gives it up in one movement, keeping none of it,
// for the pane to pass straight to polkit. Unless the conversation says the
// answer may be seen — a user name, a code read off a phone — it is drawn
// as dots, can be neither copied nor dragged out, and is kept from the input
// method's suggestions.
Rectangle {
    id: root

    // what the conversation asked, as PAM put it: "Password: "
    property string prompt: ""
    // the answer may be shown as it is typed
    property bool echo: false
    // the conversation is waiting for an answer; until it is, typing does
    // nothing, and Return asks for nothing
    property bool ready: true

    readonly property bool empty: input.length === 0
    // the prompt as a placeholder: PAM ends it with a colon, for a terminal
    readonly property string placeholder: root.prompt.replace(/[\s:]+$/, "") || "Password"

    // Return, while the conversation is waiting
    signal accepted
    // something was typed or taken away, by hand
    signal edited

    function take(): void {
        input.forceActiveFocus();
    }

    function clear(): void {
        input.clear();
    }

    // What was typed, and the field empty again in the same breath.
    function handOver(): string {
        const response = input.text;
        input.clear();
        return response;
    }

    implicitHeight: row.implicitHeight + Theme.space2 * 2

    radius: Theme.radiusMedium
    color: input.activeFocus ? Theme.surfaceHover : Theme.surface

    Behavior on color {
        ColorFade {}
    }

    // Under the row: anywhere on the field puts the caret in it.
    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.IBeamCursor

        onPressed: Nav.pointer()
        onClicked: input.forceActiveFocus()
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: Theme.space2

        spacing: Theme.space2

        Glyph {
            Layout.alignment: Qt.AlignVCenter

            text: Icons.key
            color: input.activeFocus ? Theme.text : Theme.textMuted
        }

        Item {
            Layout.fillWidth: true

            implicitHeight: input.implicitHeight

            TextInput {
                id: input

                anchors.fill: parent

                // a field is somewhere tab goes, which a bare TextInput is not
                activeFocusOnTab: true
                readOnly: !root.ready
                echoMode: root.echo ? TextInput.Normal : TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | (root.echo ? 0 : Qt.ImhHiddenText)
                persistentSelection: false

                color: root.ready ? Theme.text : Theme.textFaint
                selectionColor: Theme.accentSurface
                selectedTextColor: Theme.text

                font.family: Theme.sansFamily
                font.pixelSize: Theme.fontBody

                verticalAlignment: TextInput.AlignVCenter
                clip: true

                Accessible.role: Accessible.EditableText
                Accessible.name: root.placeholder
                Accessible.passwordEdit: !root.echo

                onTextEdited: root.edited()

                // typing is using the keyboard, so the ring comes on; escape
                // is not the field's, and goes on to the pane
                Keys.onPressed: event => {
                    Nav.key();
                    if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
                        return;

                    if (root.ready)
                        root.accepted();
                    event.accepted = true;
                }
            }

            Sans {
                anchors.fill: parent

                visible: root.empty

                text: root.placeholder
                color: Theme.textDim
            }
        }
    }

    FocusRing {
        active: input.activeFocus
        radius: root.radius
    }
}
