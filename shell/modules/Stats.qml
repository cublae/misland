import QtQuick
import qs.components
import qs.config
import qs.notch
import qs.services

// Battery, CPU and memory meters.
Row {
    id: root

    spacing: Theme.gap

    readonly property bool hasBattery: Battery.available
    readonly property real batteryLevel: Battery.level
    readonly property bool charging: Battery.pluggedIn

    readonly property int count: hasBattery ? 3 : 2
    readonly property real meterWidth: (width - spacing * (count - 1)) / count

    function duration(hours: real): string {
        if (!hours || hours <= 0 || hours > 48) return "";
        const h = Math.floor(hours);
        const m = Math.round((hours - h) * 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    Binding {
        target: SysStats
        property: "active"
        value: NotchState.expanded
    }

    Meter {
        visible: root.hasBattery
        width: root.meterWidth
        icon: root.charging ? "battery_charging_full"
            : root.batteryLevel > 0.9 ? "battery_full"
            : "battery_" + Math.max(0, Math.min(6, Math.floor(root.batteryLevel * 7))) + "_bar"
        title: "Battery"
        value: root.batteryLevel
        valueText: Math.round(root.batteryLevel * 100) + "%"
        detail: Battery.status === "Full" ? "Full"
            : Battery.status === "Not charging" ? "Plugged in"
            : root.duration(Battery.hoursLeft) || (Battery.charging ? "Charging" : "")
        barColor: root.charging ? Theme.good : root.batteryLevel < 0.15 ? Theme.danger : Theme.text
    }

    Meter {
        width: root.meterWidth
        icon: "memory"
        title: "CPU"
        value: SysStats.cpu
        valueText: Math.round(SysStats.cpu * 100) + "%"
        barColor: SysStats.cpu > 0.85 ? Theme.warn : Theme.text
    }

    Meter {
        width: root.meterWidth
        icon: "memory_alt"
        title: "Memory"
        value: SysStats.memory
        valueText: Math.round(SysStats.memory * 100) + "%"
        detail: `${SysStats.memUsedGiB.toFixed(1)} / ${SysStats.memTotalGiB.toFixed(0)} GB`
        barColor: SysStats.memory > 0.85 ? Theme.warn : Theme.text
    }

    component Meter: Card {
        id: meter

        property string icon
        property string title
        property real value
        property string valueText
        property string detail
        property color barColor: Theme.text

        implicitHeight: 62 * Theme.s

        Icon {
            id: meterIcon
            x: meter.padding
            y: meter.padding - 2 * Theme.s
            name: meter.icon
            size: 18 * Theme.s
            color: Theme.textDim
        }

        Label {
            anchors.left: meterIcon.right
            anchors.leftMargin: 6 * Theme.s
            anchors.verticalCenter: meterIcon.verticalCenter
            text: meter.title
            size: 12
            color: Theme.textDim
        }

        Label {
            id: valueLabel
            anchors.right: parent.right
            anchors.rightMargin: meter.padding
            anchors.verticalCenter: meterIcon.verticalCenter
            text: meter.valueText
            size: 13
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }

        Label {
            anchors.right: valueLabel.left
            anchors.rightMargin: 8 * Theme.s
            anchors.baseline: valueLabel.baseline
            text: meter.detail
            size: 11
            color: Theme.textDim
            visible: text !== ""
        }

        Rectangle {
            id: bar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: meter.padding
            height: 4 * Theme.s
            radius: height / 2
            color: Theme.track

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, meter.value))
                height: parent.height
                radius: parent.radius
                color: meter.barColor

                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }
}
