pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Backlight brightness via sysfs (read) and brightnessctl (write).
// sysfs does not emit inotify events, so the value is polled; reading a
// sysfs file is cheap and spawns nothing.
Singleton {
    id: root

    property string device: Config.brightness.device
    property int max: 0
    property int raw: 0

    readonly property bool available: device !== "" && max > 0
    readonly property real value: available ? raw / max : 0

    function set(v: real): void {
        if (!available) return;
        const pct = Math.round(Math.max(0.01, Math.min(1, v)) * 100);
        raw = Math.round(pct / 100 * max);
        setter.command = ["brightnessctl", "-q", "-d", device, "set", pct + "%"];
        setter.running = true;
    }

    // Find the first backlight device when none is configured.
    Process {
        running: Config.brightness.device === ""
        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        path: root.device ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text())
    }

    FileView {
        id: current
        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        onLoaded: root.raw = parseInt(text())
    }

    Timer {
        running: root.available && !setter.running
        interval: 250
        repeat: true
        onTriggered: current.reload()
    }

    Process { id: setter }
}
