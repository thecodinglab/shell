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

    readonly property bool empty: input.text.length === 0
    readonly property alias typing: input.activeFocus

    // escape, on a field that is already empty: there is nothing left here to
    // back out of, so whoever owns the field gets to decide what is
    signal cancelled

    function clear(): void {
        input.text = "";
    }

    function take(): void {
        input.forceActiveFocus();
    }

    implicitWidth: row.implicitWidth + Theme.space2 * 2
    implicitHeight: row.implicitHeight + Theme.space2 * 2

    radius: Theme.radiusMedium
    color: input.activeFocus ? Theme.surfaceHover : Theme.surface

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
        anchors.margins: Theme.space2

        spacing: Theme.space2

        Glyph {
            Layout.alignment: Qt.AlignVCenter

            text: Icons.search
            color: input.activeFocus ? Theme.text : Theme.textMuted
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
                font.pixelSize: Theme.fontBody

                verticalAlignment: TextInput.AlignVCenter
                clip: true

                Accessible.name: root.placeholder

                // typing is using the keyboard, so the ring comes on; the
                // key itself goes on to the field
                Keys.onPressed: Nav.key()

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
            }
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter

            visible: !root.empty

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
        active: input.activeFocus
        radius: root.radius
    }
}
