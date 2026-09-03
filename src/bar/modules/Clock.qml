import QtQuick
import Quickshell
import qs.config
import qs.widgets

ModuleText {
    text: {
        const locale = Config.locale ? Qt.locale(Config.locale) : Qt.locale();
        return clock.date.toLocaleString(locale, "HH:mm  –  dd. MMMM yyyy");
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}
