import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.components
import qs.config
import qs.notch
import qs.services

Column {
    id: root

    spacing: Theme.gap

    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)

    // Open menu below the tiles: "wifi", "bluetooth" or "".
    property string menu: ""

    function toggleMenu(name: string): void {
        menu = menu === name ? "" : name;
    }

    Connections {
        target: NotchState
        function onOpenChanged() { if (!NotchState.open) root.menu = ""; }
    }

    Row {
        width: parent.width
        spacing: Theme.gap

        Tile {
            width: (parent.width - parent.spacing) / 2
            icon: !Networking.wifiEnabled ? "wifi_off"
                : !root.wifiNetwork ? "wifi_find"
                : root.wifiNetwork.signalStrength > 0.66 ? "wifi"
                : root.wifiNetwork.signalStrength > 0.33 ? "wifi_2_bar" : "wifi_1_bar"
            title: "Wi-Fi"
            subtitle: !Networking.wifiEnabled ? "Off"
                : !root.wifiNetwork ? "Not connected"
                : "Connected"
            active: Networking.wifiEnabled && root.wifiNetwork !== null
            available: root.wifiDevice !== null && Networking.wifiHardwareEnabled
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            expandable: true
            expanded: root.menu === "wifi"
            onExpandClicked: root.toggleMenu("wifi")
        }

        Tile {
            width: (parent.width - parent.spacing) / 2
            icon: !root.adapter?.enabled ? "bluetooth_disabled"
                : root.btConnected.length > 0 ? "bluetooth_connected" : "bluetooth"
            title: "Bluetooth"
            subtitle: !root.adapter ? "Unavailable"
                : !root.adapter.enabled ? "Off"
                : root.btConnected.length > 0 ? root.btConnected.map(d => d.name).join(", ")
                : "On"
            active: root.adapter?.enabled ?? false
            available: root.adapter !== null
            onClicked: root.adapter.enabled = !root.adapter.enabled
            expandable: true
            expanded: root.menu === "bluetooth"
            onExpandClicked: root.toggleMenu("bluetooth")
        }
    }

    WifiMenu {
        width: parent.width
        visible: root.menu === "wifi"
        device: root.wifiDevice
    }

    BluetoothMenu {
        width: parent.width
        visible: root.menu === "bluetooth"
    }

    PillSlider {
        width: parent.width
        icon: Audio.icon
        label: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
        value: Audio.muted ? 0 : Audio.volume
        opacity: Audio.ready ? 1 : 0.4
        onMoved: v => Audio.setVolume(v)
    }

    PillSlider {
        width: parent.width
        visible: Brightness.available
        icon: "brightness_6"
        label: Math.round(Brightness.value * 100) + "%"
        value: Brightness.value
        onMoved: v => Brightness.set(v)
    }
}
