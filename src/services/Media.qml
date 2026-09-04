pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Every player that can be controlled, whatever is playing first.
//
// The notch shows all of them stacked rather than picking one, so a paused
// video does not disappear the moment music starts somewhere else.
//
// A player that cannot be started or stopped is left out entirely: an
// application that registered an mpris name and then went quiet is a card of
// dead buttons, which is worse than no card at all.
Singleton {
    id: root

    readonly property var players: Mpris.players.values.filter(p => p.canControl && p.canTogglePlaying).sort((a, b) => {
        if (a.isPlaying !== b.isPlaying)
            return a.isPlaying ? -1 : 1;
        // a stable tiebreak, so two paused players do not swap places while
        // you are looking at them
        return a.uniqueId - b.uniqueId;
    })

    readonly property bool playing: root.players.some(p => p.isPlaying)

    // mpris players are not obliged to announce that the playhead moved, so
    // a position is only as fresh as the last time somebody asked for it.
    Timer {
        interval: 1000
        repeat: true
        running: root.playing

        onTriggered: {
            for (const player of root.players) {
                if (player.isPlaying && player.positionSupported)
                    player.positionChanged();
            }
        }
    }
}
