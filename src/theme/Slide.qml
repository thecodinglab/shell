import QtQuick

// Something moving in a transition, where a Spring cannot go: a toast or a
// row arriving, the rest making room for it, a section of a page rising into
// place, one page making way for another. `leaf` is which of those it is, by
// hyprland's name for the nearest thing it animates.
NumberAnimation {
    property string leaf: "layersIn"

    duration: Theme.duration(leaf)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.bezier(leaf)
}
