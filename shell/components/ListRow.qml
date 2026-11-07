import QtQuick
import qs.config

// Row in a quick-settings menu: icon, name, status text on the right.
Rectangle {
    id: root

    property string icon
    property bool iconFilled: false
    property string title
    property string status
    property bool active: false
    property bool busy: false
    signal clicked

    implicitHeight: 36 * Theme.s
    radius: 10 * Theme.s
    color: area.containsMouse ? Theme.surfaceHover : "transparent"

    Behavior on color { ColorAnimation { duration: 120 } }

    Icon {
        id: leading
        x: 8 * Theme.s
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: 18 * Theme.s
        filled: root.iconFilled
        color: root.active ? Theme.accent : Theme.text
    }

    Label {
        anchors.left: leading.right
        anchors.leftMargin: 10 * Theme.s
        anchors.right: statusLabel.left
        anchors.rightMargin: 8 * Theme.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        size: 13
        font.weight: root.active ? Font.DemiBold : Font.Medium
    }

    Label {
        id: statusLabel
        anchors.right: parent.right
        anchors.rightMargin: 10 * Theme.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.status
        size: 11
        color: root.active ? Theme.accent : Theme.textDim
        opacity: root.busy ? 0.5 + 0.5 * pulse.value : 1

        // Pulses while connecting.
        QtObject {
            id: pulse
            property real value: 1
        }
        SequentialAnimation {
            running: root.busy
            loops: Animation.Infinite
            NumberAnimation { target: pulse; property: "value"; to: 0; duration: 500 }
            NumberAnimation { target: pulse; property: "value"; to: 1; duration: 500 }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
