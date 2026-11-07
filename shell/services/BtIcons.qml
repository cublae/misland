pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Material Symbols name for a Bluetooth device, from its BlueZ icon hint.
Singleton {
    function forDevice(d: BluetoothDevice): string {
        const icon = d?.icon ?? "";
        return icon.includes("headset") || icon.includes("headphone") ? "headphones"
            : icon.includes("audio") ? "speaker"
            : icon.includes("phone") ? "smartphone"
            : icon.includes("keyboard") ? "keyboard"
            : icon.includes("mouse") ? "mouse"
            : icon.includes("gaming") || icon.includes("joystick") ? "sports_esports"
            : icon.includes("computer") ? "computer"
            : "bluetooth";
    }

    // 0..1, or -1 when the device does not report a battery.
    function battery(d: BluetoothDevice): real {
        if (!d?.batteryAvailable) return -1;
        return d.battery > 1 ? d.battery / 100 : d.battery;
    }
}
