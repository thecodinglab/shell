import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.util

// A capsule you type into, at the head of a list it narrows down. The
// magnifier is its label; what is typed is the filter. A `scope` sits between
// the two as a token, for a search that has been narrowed to one kind of
// thing, so what is being searched is on screen and not only remembered.
//
// Its ground stays the same when the caret lands in it: the ring is what
// says where the keys are going, and a ground that changed as well would be
// saying it twice.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Search"
    // The size of what is typed, and of the magnifier with it. `bare` is the
    // field drawn as the head of a pane rather than as a control on a page:
    // no ground, no ring and no clear button, because the pane is the field.
    property int pixelSize: Theme.fontBody
    property bool bare: false
    property int padding: Theme.space2
    property Scheme scheme: Theme.schemeOf(root)
    // what the search is narrowed to, in words; empty for everything
    property string scope: ""
    // what the list under the field has selected, for a screen reader to say
    // after the field itself: the keys stay in the field while it changes
    property string selectionLabel: ""

    readonly property bool empty: input.text.length === 0
    readonly property alias typing: input.activeFocus

    // escape, on a field that is already empty: there is nothing left here to
    // back out of, so whoever owns the field gets to decide what is
    signal cancelled
    // ...and backspace on one: out of the scope, for a field that has one
    signal backedOut
    // Delete with the caret at the end of what is typed, where it has
    // nothing of the field's left to delete: whoever owns the field may take
    // it as meant for the row the list has selected
    signal deleted

    // Return, and the arrows: a field at the head of a list of things to
    // pick from lets the keyboard pick from it without leaving the field.
    // Whoever owns the field decides what is picked and what is stepped
    // over; a field with nothing to pick from ignores them.
    signal accepted
    signal stepped(int delta)

    function clear(): void {
        input.text = "";
    }

    function take(): void {
        input.forceActiveFocus();
    }

    implicitWidth: row.implicitWidth + root.padding * 2
    implicitHeight: row.implicitHeight + root.padding * 2

    radius: height / 2
    color: root.bare ? "transparent" : root.scheme.field

    // Under the row, so the clear button and the caret get their clicks
    // first: anywhere else on the field just puts the cursor in it.
    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.IBeamCursor

        onPressed: Nav.pointer()
        onClicked: input.forceActiveFocus()
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: root.padding

        spacing: root.bare ? Theme.space3 : Theme.space2

        Glyph {
            Layout.alignment: Qt.AlignVCenter

            scheme: root.scheme
            text: Icons.search
            color: {
                if (root.bare)
                    return root.scheme.textDim;
                return input.activeFocus ? root.scheme.text : root.scheme.textMuted;
            }

            font.pixelSize: root.pixelSize
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter

            visible: root.scope !== ""

            implicitWidth: scopeLabel.implicitWidth + Theme.space2 * 2
            implicitHeight: scopeLabel.implicitHeight + Theme.space1 * 2

            radius: height / 2
            color: root.scheme.surface

            Sans {
                id: scopeLabel

                anchors.centerIn: parent

                scheme: root.scheme
                text: root.scope

                font.weight: Font.Medium
            }
        }

        Item {
            Layout.fillWidth: true

            implicitHeight: input.implicitHeight

            TextInput {
                id: input

                anchors.fill: parent

                color: root.scheme.text
                selectionColor: root.scheme.accentSurface
                selectedTextColor: root.scheme.text

                font.family: Theme.sansFamily
                font.pixelSize: root.pixelSize

                verticalAlignment: TextInput.AlignVCenter
                clip: true

                Accessible.name: root.placeholder
                Accessible.description: root.selectionLabel

                // typing is using the keyboard, so the ring comes on; the
                // key itself goes on to the field, unless it is one of the
                // few that are about the list under it rather than the text
                Keys.onPressed: event => {
                    Nav.key();

                    const ctrl = event.modifiers & Qt.ControlModifier;
                    switch (event.key) {
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.accepted();
                        break;
                    case Qt.Key_Down:
                        root.stepped(1);
                        break;
                    case Qt.Key_Up:
                        root.stepped(-1);
                        break;
                    // with nothing left to delete, the scope is the next thing
                    // back, and whoever owns the field decides what that means
                    case Qt.Key_Backspace:
                        if (input.text.length > 0)
                            return;
                        root.backedOut();
                        break;
                    case Qt.Key_Delete:
                        if (input.cursorPosition < input.length || input.selectedText !== "")
                            return;
                        root.deleted();
                        break;
                    // the emacs and vi pairs, for hands that never leave home row
                    case Qt.Key_N:
                    case Qt.Key_J:
                        if (!ctrl)
                            return;
                        root.stepped(1);
                        break;
                    case Qt.Key_P:
                    case Qt.Key_K:
                        if (!ctrl)
                            return;
                        root.stepped(-1);
                        break;
                    default:
                        return;
                    }

                    event.accepted = true;
                }

                Keys.onEscapePressed: event => {
                    if (input.text.length > 0)
                        input.text = "";
                    else
                        root.cancelled();

                    event.accepted = true;
                }
            }

            Sans {
                anchors.fill: parent

                visible: root.empty

                scheme: root.scheme
                text: root.placeholder
                color: root.scheme.placeholder

                font.pixelSize: root.pixelSize
            }
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter

            // a full target, reaching into the field's padding rather than
            // making the field taller the moment there is something to clear
            Layout.topMargin: Math.min(0, (input.implicitHeight - Theme.actionSize) / 2)
            Layout.bottomMargin: Math.min(0, (input.implicitHeight - Theme.actionSize) / 2)

            visible: !root.empty && !root.bare

            scheme: root.scheme
            icon: Icons.close
            label: "Clear"
            size: Theme.actionSize
            pixelSize: Theme.fontSmall

            onClicked: {
                root.clear();
                input.forceActiveFocus();
            }
        }
    }

    FocusRing {
        scheme: root.scheme
        active: input.activeFocus && !root.bare
        radius: root.radius
    }
}
