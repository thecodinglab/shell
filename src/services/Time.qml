pragma Singleton

import QtQuick
import Quickshell
import qs.config

// One clock for the whole shell, so the collapsed notch and the panel behind
// it can never disagree about the time.
Singleton {
    id: root

    readonly property date now: clock.date
    readonly property var locale: Config.locale ? Qt.locale(Config.locale) : Qt.locale()

    readonly property string time: root.now.toLocaleString(root.locale, Config.twelveHour ? "h:mm AP" : "HH:mm")
    readonly property string date: root.now.toLocaleString(root.locale, "dddd, d MMMM")

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }
}
