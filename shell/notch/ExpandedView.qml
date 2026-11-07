import QtQuick
import qs.config
import qs.modules
import qs.services

// Expanded notch:
//   time / date                     power buttons
//   calendar | media
//            | Wi-Fi  Bluetooth
//            | volume, brightness
//   battery  cpu  memory
//   notification history (when not empty)
Item {
    id: root

    readonly property real headerHeight: header.height

    implicitWidth: 720 * Theme.s
    implicitHeight: layout.implicitHeight

    Column {
        id: layout

        width: parent.width
        spacing: Theme.gap

        Item {
            id: header

            width: parent.width
            height: 62 * Theme.s

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 4 * Theme.s
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: Time.format(Config.clock.timeFormat)
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 38 * Theme.s
                    font.weight: Font.Light
                    font.features: { "tnum": 1 }
                }

                Text {
                    text: Time.format("dddd, MMMM d")
                    color: Theme.textDim
                    font.family: Theme.font
                    font.pixelSize: 13 * Theme.s
                    font.weight: Font.Medium
                }
            }

            PowerButtons {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            width: parent.width
            spacing: Theme.gap

            Calendar {
                id: calendar
            }

            Column {
                width: parent.width - calendar.width - parent.spacing
                spacing: Theme.gap

                MediaCard {
                    width: parent.width
                }

                QuickSettings {
                    width: parent.width
                }
            }
        }

        Stats {
            width: parent.width
        }

        NotificationList {
            width: parent.width
        }
    }
}
