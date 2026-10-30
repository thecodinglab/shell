import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.util

// A row you type into, on the raised ground, at the head of a list it
// narrows down. The magnifier is its label; what is typed is the filter.
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

    readonly property bool empty: input.text.length === 0
    readonly property alias typing: input.activeFocus

    // escape, on a field that is already empty: there is nothing left here to
    // back out of, so whoever owns the field gets to decide what is
    signal cancelled

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

    radius: Theme.radiusMedium
    color: {
        if (root.bare)
            return "transparent";
        return input.activeFocus ? Theme.surfaceHover : Theme.surface;
    }

    Behavior on color {
        ColorFade {}
    }

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

            text: Icons.search
            color: {
                if (root.bare)
                    return Theme.textDim;
                return input.activeFocus ? Theme.text : Theme.textMuted;
            }

            font.pixelSize: root.pixelSize
        }

        Item {
            Layout.fillWidth: true

            implicitHeight: input.implicitHeight

            TextInput {
                id: input

                anchors.fill: parent

                color: Theme.text
                selectionColor: Theme.accentSurface
                selectedTextColor: Theme.text

                font.family: Theme.sansFamily
                font.pixelSize: root.pixelSize

                verticalAlignment: TextInput.AlignVCenter
                clip: true

                Accessible.name: root.placeholder

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

                text: root.placeholder
                color: Theme.textDim

                font.pixelSize: root.pixelSize
            }
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter

            visible: !root.empty && !root.bare

            icon: Icons.close
            label: "Clear"
            size: Theme.space5
            pixelSize: Theme.fontSmall

            onClicked: {
                root.clear();
                input.forceActiveFocus();
            }
        }
    }

    FocusRing {
        active: input.activeFocus && !root.bare
        radius: root.radius
    }
}
