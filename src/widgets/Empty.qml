import QtQuick
import QtQuick.Layouts
import qs.theme

// What a panel says when it has nothing to list: one quiet line, on the
// same left edge the rows would have started on, and a spinner ahead of it
// while it is still looking.
RowLayout {
    id: root

    property Scheme scheme: Theme.schemeOf(root)

    property string text: ""
    property bool busy: false

    Layout.fillWidth: true
    Layout.topMargin: Theme.space1

    spacing: Theme.rowSpacing

    Spinner {
        Layout.alignment: Qt.AlignVCenter

        visible: root.busy
        scheme: root.scheme
    }

    Sans {
        Layout.fillWidth: true

        scheme: root.scheme
        text: root.text
        color: root.scheme.textDim

        wrapMode: Text.Wrap
    }
}
