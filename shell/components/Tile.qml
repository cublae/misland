import QtQuick
import qs.config

// Quick-settings toggle: round icon that lights up when active, plus a
// title and a subtitle (e.g. the connected network). With `expandable`, a
// chevron on the right opens a menu; the rest of the tile still toggles.
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool active: false
    property bool available: true
    property bool expandable: false
    property bool expanded: false
    signal clicked
    signal expandClicked

    implicitHeight: 50 * Theme.s
    radius: Theme.radius
    color: area.containsMouse ? Theme.surfaceHover : Theme.surface
    opacity: available ? 1 : 0.4

    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
        id: bubble
        x: 9 * Theme.s
        anchors.verticalCenter: parent.verticalCenter
        width: 32 * Theme.s
        height: width
        radius: width / 2
        color: root.active ? Theme.accent : Theme.track

        Behavior on color { ColorAnimation { duration: 160 } }

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: 18 * Theme.s
            filled: root.active
        }
    }

    Column {
        anchors.left: bubble.right
        anchors.leftMargin: 9 * Theme.s
        anchors.right: root.expandable ? chevron.left : parent.right
        anchors.rightMargin: (root.expandable ? 2 : 10) * Theme.s
        anchors.verticalCenter: parent.verticalCenter

        Label {
            width: parent.width
            text: root.title
            size: 13
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            text: root.subtitle
            size: 11
            color: Theme.textDim
            visible: text !== ""
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.available) root.clicked()
    }

    Rectangle {
        id: chevron

        anchors.right: parent.right
        anchors.rightMargin: 8 * Theme.s
        anchors.verticalCenter: parent.verticalCenter
        visible: root.expandable
        width: 30 * Theme.s
        height: width
        radius: width / 2
        color: chevronArea.containsMouse ? Theme.track : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }

        Icon {
            anchors.centerIn: parent
            name: "expand_more"
            color: Theme.textDim
            rotation: root.expanded ? 180 : 0

            Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: chevronArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expandClicked()
        }
    }
}
