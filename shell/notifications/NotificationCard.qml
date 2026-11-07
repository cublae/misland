import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.components
import qs.config
import qs.services

// One notification: icon, app name and age, summary, body, actions.
// Clicking the card runs the default action and removes it; the close
// button appears on hover.
Rectangle {
    id: root

    required property Notification notification
    property bool compact: false
    readonly property alias hovered: hover.hovered
    signal closeRequested

    readonly property string iconSource: {
        const n = notification;
        if (!n) return "";
        if (n.image) return n.image;
        if (n.appIcon.startsWith("/") || n.appIcon.startsWith("file://")) return n.appIcon;
        return n.appIcon ? Quickshell.iconPath(n.appIcon, true) : "";
    }
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical

    implicitHeight: content.implicitHeight + 2 * pad
    readonly property real pad: (compact ? 12 : 14) * Theme.s

    radius: Theme.radius
    // Popups sit on the black corner panel, so they have no fill of their own.
    color: compact ? (hover.hovered ? Theme.surfaceHover : Theme.surface)
        : hover.hovered ? Theme.surface : "transparent"
    border.width: !compact && critical ? 1 : 0
    border.color: Theme.danger

    Behavior on color { ColorAnimation { duration: 120 } }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.activate(root.notification)
    }

    Row {
        id: content

        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: 10 * Theme.s

        Rectangle {
            id: iconBox

            width: (root.compact ? 32 : 38) * Theme.s
            height: width
            radius: 10 * Theme.s
            color: image.status === Image.Ready ? "transparent" : Theme.track

            Icon {
                anchors.centerIn: parent
                name: "notifications"
                filled: true
                color: Theme.textDim
                visible: image.status !== Image.Ready
            }

            Image {
                id: image
                anchors.fill: parent
                source: root.iconSource
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                sourceSize.width: width * 2
                sourceSize.height: height * 2
            }
        }

        Column {
            width: parent.width - iconBox.width - parent.spacing
            spacing: 2 * Theme.s

            Item {
                width: parent.width
                height: appName.height

                Label {
                    id: appName
                    width: parent.width - age.width - 30 * Theme.s
                    text: root.notification?.appName || "Notification"
                    size: 11
                    color: Theme.textDim
                }

                Label {
                    id: age
                    anchors.right: parent.right
                    anchors.rightMargin: closeButton.visible ? closeButton.width + 4 * Theme.s : 0
                    text: Notifications.age(root.notification?.id ?? -1)
                    size: 11
                    color: Theme.textFaint
                }

                IconButton {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 22 * Theme.s
                    icon: "close"
                    iconSize: 15 * Theme.s
                    iconColor: Theme.textDim
                    visible: root.hovered
                    onClicked: root.closeRequested()
                }
            }

            Label {
                width: parent.width
                text: root.notification?.summary ?? ""
                size: 13
                font.weight: Font.DemiBold
                visible: text !== ""
            }

            Label {
                width: parent.width
                text: root.notification?.body ?? ""
                textFormat: Text.StyledText
                size: 12
                color: Theme.textDim
                wrapMode: Text.Wrap
                maximumLineCount: root.compact ? 2 : 4
                visible: text !== ""
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Row {
                topPadding: 6 * Theme.s
                spacing: 6 * Theme.s
                visible: actions.count > 0

                Repeater {
                    id: actions
                    model: root.notification?.actions.filter(a => a.identifier !== "default") ?? []

                    Rectangle {
                        required property NotificationAction modelData

                        implicitWidth: actionLabel.implicitWidth + 20 * Theme.s
                        implicitHeight: 26 * Theme.s
                        radius: height / 2
                        color: actionHover.hovered ? Theme.surfaceHover : Theme.track

                        HoverHandler { id: actionHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modelData.invoke();
                                root.notification.dismiss();
                            }
                        }

                        Label {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            size: 11
                        }
                    }
                }
            }
        }
    }
}
