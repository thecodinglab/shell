import QtQuick

// A ground or an ink changing, the way hyprland moves a border to the window
// that has just taken the focus: most of the way at once, and settling from
// there.
ColorAnimation {
    property string leaf: "border"

    duration: Theme.duration(leaf)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.bezier(leaf)
}
