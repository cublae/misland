import QtQuick
import qs.config

// Control-Center style slider: a pill whose white fill is the value,
// with the icon sitting inside. Drag, click or scroll to change it.
Item {
    id: root

    property real value: 0          // 0..1
    property string icon
    property string label
    signal moved(real value)

    implicitHeight: 34 * Theme.s

    function setFromX(x: real): void {
        root.moved(Math.max(0, Math.min(1, x / width)));
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.track
        clip: true

        Rectangle {
            width: Math.max(track.height, track.width * root.value)
            height: parent.height
            radius: track.radius
            color: Theme.text

            Behavior on width {
                enabled: !area.pressed
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }
    }

    Icon {
        x: (track.height - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        width: track.height
        name: root.icon
        size: 18 * Theme.s
        filled: true
        color: Theme.background
    }

    Label {
        anchors.right: parent.right
        anchors.rightMargin: 12 * Theme.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        size: 11
        color: root.value > 0.85 ? Theme.background : Theme.textDim
        font.features: { "tnum": 1 }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFromX(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.setFromX(mouse.x); }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
