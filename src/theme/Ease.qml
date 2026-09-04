import QtQuick

// A small thing moving a short way — a knob, a dot, a rail growing under the
// pointer — on the plain cubic. The slab's own curve is only legible over a
// distance; see Slide.
NumberAnimation {
    duration: Theme.fadeDuration
    easing.type: Theme.expandEasing
}
