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

    // The date without its year, in the order and the words the locale writes
    // a long date in — "Monday, November 2", "Montag, 2. November" — rather
    // than in one order for everybody. The year is cut off the end of the
    // locale's own long format, with the word some languages set either side
    // of it ("de", "г."); a locale that does not end on the year keeps it,
    // since cutting it out of the middle would leave the rest out of order.
    readonly property string dateFormat: root.locale.dateFormat(Locale.LongFormat).replace(/(?:[\s,.]*'[^']*')?[\s,.]*y+\.?(?:\s*'[^']*'\.?)?\s*$/, "")

    readonly property string time: root.now.toLocaleString(root.locale, Config.twelveHour ? "h:mm AP" : "HH:mm")
    readonly property string date: root.now.toLocaleString(root.locale, root.dateFormat)

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }
}
