import QtQuick
import QtQuick.Layouts
import qs.theme

// A row you type into, on the same ground as a ListRow so it sits at the head
// of a list without looking like it came from somewhere else.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Search"
    property int padding: Theme.px(10)

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

    implicitWidth: row.implicitWidth + root.padding * 2
    implicitHeight: row.implicitHeight + root.padding * 2

    radius: Theme.cardRadius
    color: input.activeFocus ? Theme.surfaceHover : Theme.surface

    Behavior on color {
        ColorAnimation {
            duration: Theme.fadeDuration
        }
    }

    // Under the row, so the clear button and the caret get their clicks
    // first: anywhere else on the field just puts the cursor in it.
    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.IBeamCursor

        onClicked: input.forceActiveFocus()
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: root.padding

        spacing: Theme.rowSpacing

        Glyph {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Theme.px(2)

            text: Icons.search
            color: input.activeFocus ? Theme.textBody : Theme.textMuted
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
            size: Theme.px(20)
            pixelSize: Theme.fontSmall

            onClicked: {
                root.clear();
                input.forceActiveFocus();
            }
        }
    }
}
