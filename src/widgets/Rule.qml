import QtQuick
import QtQuick.Layouts
import qs.theme

// A hairline: the one line the surface draws, between two rows of a list or
// two sections of a page.
Rectangle {
    Layout.fillWidth: true

    implicitHeight: 1
    color: Theme.rule
}
