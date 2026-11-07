import QtQuick
import qs.config
import qs.services

// Collapsed content: "14:35 · Mon, Nov 8".
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
}
