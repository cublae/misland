pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.config
import qs.notch

// Live activities: short-lived content the collapsed notch grows to show
// (volume, brightness, charger, Bluetooth devices, track changes).
//
// `current` is a plain object:
//   { kind, icon, art, color, title, subtitle, value (0..1 or -1), valueText }
Singleton {
    id: root

    property var current: null

    // Ignore the burst of "changes" while services report initial state.
    property bool armed: false

    function show(activity: var, ms: int): void {
        if (!armed || NotchState.open) return;
        current = Object.assign({ icon: "", art: "", color: "", title: "", subtitle: "", value: -1, valueText: "" }, activity);
        hide.interval = ms;
        hide.restart();
    }

    Timer {
        running: true
        interval: 2000
        onTriggered: root.armed = true
    }

    Timer {
        id: hide
        onTriggered: root.current = null
    }

    // Opening the panel replaces whatever was showing.
    Connections {
        target: NotchState
        function onOpenChanged() { if (NotchState.open) root.current = null; }
    }

    // Volume.
    Connections {
        target: Audio
        enabled: Config.activities.volume

        function onVolumeChanged() { osd(); }
        function onMutedChanged() { osd(); }

        function osd(): void {
            root.show({
                kind: "volume",
                icon: Audio.icon,
                value: Audio.muted ? 0 : Audio.volume,
                valueText: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
            }, 1600);
        }
    }

    // Brightness.
    Connections {
        target: Brightness
        enabled: Config.activities.brightness

        function onValueChanged() {
            root.show({
                kind: "brightness",
                icon: "brightness_6",
                value: Brightness.value,
                valueText: Math.round(Brightness.value * 100) + "%"
            }, 1600);
        }
    }

    // Charger plugged in or out.
    Connections {
        target: Battery
        enabled: Config.activities.power

        function onPluggedInChanged() {
            root.show({
                kind: "power",
                icon: Battery.pluggedIn ? "bolt" : "battery_full",
                title: Battery.pluggedIn ? "Charging" : "On battery",
                valueText: Math.round(Battery.level * 100) + "%"
            }, 2500);
        }
    }

    // Bluetooth devices connecting or disconnecting.
    Instantiator {
        model: Config.activities.bluetooth ? Bluetooth.devices : null

        delegate: Connections {
            required property BluetoothDevice modelData
            target: modelData

            function onConnectedChanged() {
                const d = modelData;
                const battery = BtIcons.battery(d);
                root.show({
                    kind: "bluetooth",
                    icon: BtIcons.forDevice(d),
                    title: d.name,
                    subtitle: d.connected ? "Connected" : "Disconnected",
                    valueText: d.connected && battery >= 0 ? Math.round(battery * 100) + "%" : ""
                }, 3000);
            }
        }
    }

    // Track changes. Title and artist update separately, so wait a moment.
    readonly property string trackKey: Media.player
        ? `${Media.player.trackTitle}\n${Media.player.trackArtist}` : ""

    onTrackKeyChanged: if (Config.activities.track) trackSettle.restart()

    Timer {
        id: trackSettle
        interval: 350
        onTriggered: {
            const p = Media.player;
            if (!p?.trackTitle) return;
            root.show({
                kind: "track",
                icon: "music_note",
                art: p.trackArtUrl,
                title: p.trackTitle,
                subtitle: p.trackArtist || p.identity
            }, 4000);
        }
    }
}
