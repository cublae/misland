pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Battery state straight from /sys/class/power_supply, so it works without
// the UPower daemon. Polled, because sysfs does not emit inotify events.
Singleton {
    id: root

    property string device: ""
    property real level: 0           // 0..1
    property string status: ""       // Charging, Discharging, Full, Not charging
    property real hoursLeft: 0       // to empty or to full, 0 if unknown

    readonly property bool available: device !== ""
    readonly property bool charging: status === "Charging"
    readonly property bool pluggedIn: available && status !== "Discharging"

    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/power_supply/*; do [ \"$(cat $d/type)\" = Battery ] && basename $d && break; done"]
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    Timer {
        running: root.available
        interval: 2000
        repeat: true
        onTriggered: uevent.reload()
    }

    // uevent holds every value in one KEY=value file. FileView reads it as
    // soon as the path is set; the timer refreshes it.
    FileView {
        id: uevent
        path: root.device ? `/sys/class/power_supply/${root.device}/uevent` : ""
        onLoaded: {
            const v = {};
            for (const line of text().split("\n")) {
                const i = line.indexOf("=");
                if (i > 0) v[line.slice(13, i)] = line.slice(i + 1); // strip POWER_SUPPLY_
            }
            root.level = Number(v.CAPACITY ?? 0) / 100;
            root.status = v.STATUS ?? "";

            // Charge (µAh/µA) or energy (µWh/µW), whichever the driver exposes.
            const now = Number(v.CHARGE_NOW ?? v.ENERGY_NOW ?? 0);
            const full = Number(v.CHARGE_FULL ?? v.ENERGY_FULL ?? 0);
            const rate = Math.abs(Number(v.CURRENT_NOW ?? v.POWER_NOW ?? 0));
            root.hoursLeft = rate <= 0 ? 0
                : root.status === "Discharging" ? now / rate
                : root.status === "Charging" ? (full - now) / rate : 0;
        }
    }
}
