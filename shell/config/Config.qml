pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User settings, read from $MISLAND_CONFIG or ~/.config/misland/config.json.
// The home-manager module generates that file; every key is optional.
// The file is watched, so edits apply live.
Singleton {
    id: root

    readonly property string path: Quickshell.env("MISLAND_CONFIG")
        || (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/misland/config.json"

    // Output name (e.g. "DP-5"). Empty = first screen Quickshell reports.
    property alias screen: adapter.screen
    // Multiplier on top of the automatic, resolution-based scale.
    property alias scale: adapter.scale
    // Reserve the collapsed notch height so tiled windows sit below it.
    property alias reserveSpace: adapter.reserveSpace
    property alias clock: adapter.clock
    property alias calendar: adapter.calendar
    property alias brightness: adapter.brightness
    property alias power: adapter.power
    property alias notifications: adapter.notifications
    property alias activities: adapter.activities
    property alias edges: adapter.edges
    property alias launcher: adapter.launcher
    property alias clipboard: adapter.clipboard
    property alias colorPicker: adapter.colorPicker
    property alias animation: adapter.animation

    FileView {
        path: root.path
        watchChanges: true
        blockLoading: true
        printErrors: false
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property string screen: ""
            property real scale: 1.0
            property bool reserveSpace: true

            property JsonObject clock: JsonObject {
                // Qt date/time format strings, English locale.
                property string timeFormat: "HH:mm"
                property string dateFormat: "ddd, MMM d"
                property string separator: "·"
            }

            property JsonObject calendar: JsonObject {
                // 1 = Monday ... 7 = Sunday.
                property int firstDayOfWeek: 1
            }

            property JsonObject brightness: JsonObject {
                // /sys/class/backlight entry. Empty = first one found.
                property string device: ""
            }

            property JsonObject power: JsonObject {
                property list<string> lock: ["loginctl", "lock-session"]
                property list<string> suspend: ["systemctl", "suspend"]
                // Empty = exit Hyprland through its IPC.
                property list<string> logout: []
                property list<string> reboot: ["systemctl", "reboot"]
                property list<string> poweroff: ["systemctl", "poweroff"]
            }

            property JsonObject notifications: JsonObject {
                // Seconds a popup stays up when the app does not say.
                property real timeout: 5
                property int maxHistory: 50
            }

            property JsonObject activities: JsonObject {
                property bool volume: true
                property bool brightness: true
                property bool power: true
                property bool bluetooth: true
                property bool track: true
            }

            property JsonObject edges: JsonObject {
                // Touching the top edge left of the notch drops the workspaces,
                // right of it the tray.
                property bool workspaces: true
                property bool tray: true
                // Hover strip: thickness in px, length as a fraction of the
                // screen width on each side.
                property real triggerSize: 2
                property real triggerLength: 0.35
                // Workspaces always listed, even when empty.
                property int persistentWorkspaces: 5
            }

            property JsonObject launcher: JsonObject {
                property int maxResults: 7
                // Prefix for desktop entries with Terminal=true.
                property list<string> terminal: ["kitty", "-e"]
            }

            property JsonObject clipboard: JsonObject {
                // Record clipboard history with `wl-paste --watch cliphist store`.
                // Turn off if something else already feeds cliphist.
                property bool watch: true
                property int maxItems: 100
            }

            property JsonObject colorPicker: JsonObject {
                // hyprpicker output format: hex, rgb, hsl, hsv or cmyk.
                property string format: "hex"
            }

            property JsonObject animation: JsonObject {
                // SpringAnimation parameters; lower damping = more bounce.
                property real spring: 3.2
                property real damping: 0.28
            }
        }
    }
}
