import QtQuick

// Something fading in — or, as `Fade { leaf: "fadeOut" }`, out — on the
// curve and at the speed hyprland fades its windows with.
NumberAnimation {
    property string leaf: "fadeIn"

    duration: Theme.duration(leaf)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.bezier(leaf)
}
