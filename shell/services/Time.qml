pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
    readonly property date now: clock.date
    readonly property var locale: Qt.locale("en_US")

    function format(fmt: string): string {
        return locale.toString(now, fmt);
    }

    SystemClock {
        id: clock
        // Tick every second only when a format actually shows seconds.
        precision: Config.clock.timeFormat.includes("s") ? SystemClock.Seconds : SystemClock.Minutes
    }
}
