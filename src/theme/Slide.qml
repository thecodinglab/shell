import QtQuick

// The slab's own motion, for anything that moves with it or as far as it
// does: nearly all of the distance is covered in the first third and it
// settles from there, so it arrives as fast as it can without stopping dead.
NumberAnimation {
    duration: Theme.expandDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.expandCurve
}
