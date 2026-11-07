import QtQuick
import qs.config

// Round icon button with a hover highlight.
Rectangle {
    id: root

    property alias icon: glyph.name
    property alias iconSize: glyph.size
    property alias filled: glyph.filled
    property color iconColor: Theme.text
    property color hoverColor: Theme.surfaceHover
    property bool highlighted: false
    property color highlightColor: Theme.accent
    signal clicked

    implicitWidth: 32 * Theme.s
    implicitHeight: implicitWidth
    radius: width / 2
    color: highlighted ? highlightColor
        : area.containsMouse && enabled ? hoverColor : "transparent"
    opacity: enabled ? 1 : 0.35

    Behavior on color { ColorAnimation { duration: 120 } }

    Icon {
        id: glyph
        anchors.centerIn: parent
        color: root.iconColor
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
