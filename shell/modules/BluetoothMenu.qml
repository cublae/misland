import QtQuick
import Quickshell.Bluetooth
import qs.components
import qs.config
import qs.services

// Bluetooth devices: connected first, then paired, then ones found nearby.
// Click to connect, disconnect or pair. Discovers while open.
Card {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property real maxListHeight: 200 * Theme.s

    readonly property var devices: Bluetooth.devices.values
        .filter(d => d.name !== "" && d.name !== d.address.replace(/:/g, "-"))
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

    function activate(d: BluetoothDevice): void {
        if (d.connected) d.disconnect();
        else if (d.paired) d.connect();
        else {
            // Pair, then connect once BlueZ reports it paired.
            d.trusted = true;
            d.pair();
        }
    }

    implicitHeight: content.implicitHeight + 2 * padding

    Binding {
        target: root.adapter
        property: "discovering"
        value: true
        when: root.adapter !== null && root.adapter.enabled && root.visible
    }

    Column {
        id: content

        x: root.padding / 2
        y: root.padding
        width: parent.width - root.padding
        spacing: 2 * Theme.s

        Label {
            leftPadding: 8 * Theme.s
            bottomPadding: 4 * Theme.s
            text: !root.adapter ? "No Bluetooth adapter"
                : !root.adapter.enabled ? "Bluetooth is off"
                : root.devices.length === 0 ? "Searching…" : "Devices"
            size: 11
            color: Theme.textDim
        }

        Flickable {
            width: parent.width
            height: Math.min(list.implicitHeight, root.maxListHeight)
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: root.adapter?.enabled ?? false

            Column {
                id: list
                width: parent.width

                Repeater {
                    model: root.devices

                    ListRow {
                        required property BluetoothDevice modelData
                        readonly property BluetoothDevice d: modelData
                        readonly property real battery: BtIcons.battery(d)

                        width: list.width
                        icon: BtIcons.forDevice(d)
                        iconFilled: d.connected
                        title: d.name
                        active: d.connected
                        busy: d.pairing || d.state === BluetoothDeviceState.Connecting
                            || d.state === BluetoothDeviceState.Disconnecting
                        status: d.pairing ? "Pairing…"
                            : d.state === BluetoothDeviceState.Connecting ? "Connecting…"
                            : d.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                            : d.connected ? (battery >= 0 ? `${Math.round(battery * 100)}%` : "Connected")
                            : d.paired ? "Paired" : ""
                        onClicked: root.activate(d)

                        Connections {
                            target: d
                            function onPairedChanged() { if (d.paired && !d.connected) d.connect(); }
                        }
                    }
                }
            }
        }
    }
}
