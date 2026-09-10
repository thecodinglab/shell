import QtQuick
import qs.theme
import qs.util

// The ring around whatever has keyboard focus.
//
// Drawn only while the keyboard is what is being used — see Nav — so a
// control that was clicked does not get a ring telling the pointer where
// the pointer is. It sits just inside the edge of its target by default, so
// a row in a clipped list keeps all of it; `inset` pulls it outward for the
// few controls too small to hold one.
Rectangle {
    id: root

    property Item target: root.parent
    property bool active: root.target.activeFocus
    property real inset: 0

    anchors.fill: root.target
    anchors.margins: root.inset

    // in front of everything on the control it rings
    z: 100

    visible: root.active && Nav.keyboard

    color: "transparent"
    border.width: Theme.focusWidth
    border.color: Theme.accent
}
