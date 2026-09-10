import QtQuick

// A crossfade: the one duration everything small on the surface changes in.
// Every duration comes from Theme, so reduced motion turns all of them off
// at once.
NumberAnimation {
    duration: Theme.fadeDuration
}
