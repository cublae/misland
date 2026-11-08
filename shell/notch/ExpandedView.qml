import QtQuick
import qs.components
import qs.config
import qs.modules
import qs.services

// Expanded notch:
//   time / date          colour picker, clipboard | power
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

            // Tools, then power, separated by a thin divider.
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2 * Theme.s

                // Do not disturb: a red crossed-out bell while popups are silenced
                // (by hand or by screen sharing), a plain bell otherwise. The
                // red background marks the manual switch.
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Notifications.quiet ? "notifications_off" : "notifications"
                    iconSize: 19 * Theme.s
                    filled: Notifications.quiet
                    highlighted: Notifications.dnd
                    highlightColor: Qt.alpha(Theme.danger, 0.2)
                    iconColor: Notifications.quiet ? Theme.danger : Theme.textDim
                    onClicked: Notifications.dnd = !Notifications.dnd
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "colorize"
                    iconSize: 19 * Theme.s
                    iconColor: Theme.textDim
                    onClicked: ColorPicker.pick()
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "content_paste"
                    iconSize: 19 * Theme.s
                    iconColor: Theme.textDim
                    onClicked: NotchState.show("clipboard")
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 18 * Theme.s
                    color: Theme.track
                }

                PowerButtons {
                    anchors.verticalCenter: parent.verticalCenter
                }
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
