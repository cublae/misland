import QtQuick
import qs.config

// Material Symbols glyph by ligature name, e.g. Icon { name: "wifi" }.
Text {
    property string name
    property real size: 20 * Theme.s
    property bool filled: false

    text: name
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "opsz": 24, "wght": 400 })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
