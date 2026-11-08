import QtQuick
import qs.components
import qs.config
import qs.notifications
import qs.services

// Notification history inside the expanded notch. Hidden when empty so the
// panel stays compact.
Column {
    id: root

    readonly property int count: Notifications.count
    readonly property real maxListHeight: 230 * Theme.s

    visible: count > 0
    spacing: 6 * Theme.s

    Item {
        width: parent.width
        height: 26 * Theme.s

        Label {
            anchors.left: parent.left
            anchors.leftMargin: 4 * Theme.s
            anchors.verticalCenter: parent.verticalCenter
            text: `Notifications  ·  ${root.count}`
            size: 12
            color: Theme.textDim
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: clearLabel.implicitWidth + 18 * Theme.s
            implicitHeight: 24 * Theme.s
            radius: height / 2
            color: clearArea.containsMouse ? Theme.surfaceHover : Theme.surface

            Label {
                id: clearLabel
                anchors.centerIn: parent
                text: "Clear all"
                size: 11
            }

            MouseArea {
                id: clearArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.clearAll()
            }
        }
    }

    ListView {
        id: list

        width: parent.width
        height: Math.min(contentHeight, root.maxListHeight)
        clip: true
        spacing: 6 * Theme.s
        boundsBehavior: Flickable.StopAtBounds
        // The model is oldest-first; laying it out bottom-to-top puts the
        // newest on top. Start scrolled to the newest.
        model: Notifications.tracked
        verticalLayoutDirection: ListView.BottomToTop
        onCountChanged: positionViewAtEnd()

        delegate: NotificationCard {
            required property var modelData

            width: list.width
            notification: modelData
            compact: true
            onCloseRequested: modelData.dismiss()
        }
    }
}
