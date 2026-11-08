pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // UI scale of the notch's screen; set by the Notch window.
    property real s: 1

    readonly property color background: "#000000"
    readonly property color surface: "#161618"
    readonly property color surfaceHover: "#232326"
    readonly property color track: "#2c2c2e"
    readonly property color text: "#f5f5f7"
    readonly property color textDim: "#8e8e93"
    readonly property color textFaint: "#48484a"
    readonly property color accent: "#0a84ff"
    readonly property color danger: "#ff453a"
    readonly property color good: "#30d158"
    readonly property color warn: "#ffd60a"
    readonly property color orange: "#ff9f0a"

    readonly property string font: "Inter"
    readonly property string iconFont: "Material Symbols Rounded"

    // Height of the collapsed notch; the corner panels match it.
    readonly property real barHeight: Math.round(32 * s)

    readonly property real radius: 18 * s
    readonly property real gap: 10 * s
}
