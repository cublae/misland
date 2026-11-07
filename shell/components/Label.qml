import QtQuick
import qs.config

Text {
    property real size: 13

    color: Theme.text
    font.family: Theme.font
    font.pixelSize: size * Theme.s
    font.weight: Font.Medium
    elide: Text.ElideRight
}
