import QtQuick

// One section of a page rising into place under a sheet that is unfolding:
// it waits its turn, unseen and a little below where it rests, and then
// arrives the way hyprland brings a layer in. Made for the one run and gone
// after it — see `Notch.cascade`.
SequentialAnimation {
    id: root

    required property Item section
    property int delay: 0

    // how far below its place the section still is
    property real offset: Theme.riseDistance

    // A transform rather than `y`, which belongs to the layout the section
    // is in and would be put back on the next relayout; and in whole pixels,
    // or the text in it shimmers as it moves.
    property Translate shift: Translate {
        y: Math.round(root.offset)
    }

    Component.onCompleted: {
        root.section.transform = [root.shift];
        root.section.opacity = 0;
        root.start();
    }

    // Finished, or cut short by the next unfold: either way the section is
    // left where it rests and all there.
    onStopped: {
        root.section.transform = [];
        root.section.opacity = 1;
        root.destroy();
    }

    PauseAnimation {
        duration: root.delay
    }

    ParallelAnimation {
        Slide {
            target: root
            property: "offset"
            to: 0
        }

        Fade {
            target: root.section
            property: "opacity"
            to: 1
        }
    }
}
