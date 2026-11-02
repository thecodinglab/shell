import QtQuick
import QtQuick.Layouts
import qs.theme

// A hairline: the one line the surface draws, between two rows of a list or
// two sections of a page.
Rectangle {
    id: root

    property Scheme scheme: Theme.schemeOf(root)

    Layout.fillWidth: true

    implicitHeight: 1
    color: root.scheme.rule
}
