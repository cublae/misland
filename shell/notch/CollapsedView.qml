import QtQuick
import qs.components
import qs.config
import qs.services

// Collapsed content: "14:35 · Mon, Nov 8", then privacy indicators (microphone,
// camera, screen sharing) and a red crossed-out bell while popups are silenced.
Row {
    spacing: 7 * Theme.s

    Text {
        text: Time.format(Config.clock.timeFormat)
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 14 * Theme.s
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
    }

    Text {
        visible: Config.clock.dateFormat !== ""
        text: Config.clock.separator
        color: Theme.textDim
        font.family: Theme.font
        font.pixelSize: 14 * Theme.s
    }

    Text {
        visible: Config.clock.dateFormat !== ""
        text: Time.format(Config.clock.dateFormat)
        color: Theme.textDim
        font.family: Theme.font
        font.pixelSize: 14 * Theme.s
        font.weight: Font.Medium
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: 3 * Theme.s
        spacing: 5 * Theme.s
        visible: Privacy.any || Notifications.quiet

        Indicator { name: "mic"; color: Theme.orange; visible: Privacy.microphone }
        Indicator { name: "videocam"; color: Theme.good; visible: Privacy.camera }
        Indicator { name: "desktop_windows"; color: Theme.accent; visible: Privacy.screenSharing }
        Indicator { name: "notifications_off"; color: Theme.danger; visible: Notifications.quiet }
    }

    component Indicator: Icon {
        anchors.verticalCenter: parent.verticalCenter
        size: 15 * Theme.s
        filled: true
    }
}
