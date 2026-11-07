pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.notch

// Screen colour picker on top of hyprpicker. The picked value is copied to
// the clipboard and shown in the notch with a swatch.
Singleton {
    id: root

    readonly property bool picking: picker.running

    function pick(): void {
        if (picker.running) return;
        // Get the open notch out of the way first.
        NotchState.close();
        picker.running = true;
    }

    Process {
        id: picker

        command: ["hyprpicker", "--autocopy", "--format", Config.colorPicker.format]

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                // Empty when the pick was cancelled with Escape.
                if (value === "") return;
                const isHex = /^#[0-9a-f]{6}$/i.test(value);
                Activity.show({
                    kind: "color",
                    icon: "colorize",
                    color: isHex ? value : "",
                    title: isHex ? value.toUpperCase() : value,
                    subtitle: "Copied"
                }, 2500);
            }
        }
    }
}
