import QtQuick
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Content of the collapsed notch while a live activity is up:
//   [icon]  ━━━━━━━━━━  45%            volume / brightness
//   [icon]  Charging              97%  charger
//   [art]   Title · Artist      ▂▅▃    track (always one line)
Item {
    id: root

    property var activity: null

    readonly property real lead: 20 * Theme.s

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 10 * Theme.s

        Item {
            width: root.lead
            height: root.lead
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.centerIn: parent
                name: root.activity?.icon ?? ""
                size: 19 * Theme.s
                filled: true
                visible: art.status !== Image.Ready
            }

            ClippingRectangle {
                anchors.fill: parent
                radius: 5 * Theme.s
                color: "transparent"
                visible: art.status === Image.Ready

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.activity?.art ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                }
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: (root.activity?.title ?? "") !== ""
            spacing: 6 * Theme.s

            Label {
                width: Math.min(implicitWidth, 240 * Theme.s)
                text: root.activity?.title ?? ""
                size: 13
                font.weight: Font.DemiBold
            }
            Label {
                visible: subtitle.visible
                text: "·"
                size: 13
                color: Theme.textDim
            }
            Label {
                id: subtitle
                width: Math.min(implicitWidth, 180 * Theme.s)
                text: root.activity?.subtitle ?? ""
                size: 13
                color: Theme.textDim
                visible: text !== ""
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: (root.activity?.value ?? -1) >= 0
            width: 110 * Theme.s
            height: 5 * Theme.s
            radius: height / 2
            color: Theme.track

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.activity?.value ?? 0))
                height: parent.height
                radius: parent.radius
                color: Theme.text

                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            text: root.activity?.valueText ?? ""
            size: 12
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
            color: root.activity?.kind === "power" && Battery.pluggedIn ? Theme.good : Theme.text
        }

        // Little equalizer for track changes.
        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.activity?.kind === "track"
            spacing: 2 * Theme.s
            height: 14 * Theme.s

            Repeater {
                model: 3

                Rectangle {
                    required property int index

                    anchors.bottom: parent.bottom
                    width: 3 * Theme.s
                    radius: width / 2
                    color: Theme.text
                    height: parent.height * 0.4

                    SequentialAnimation on height {
                        running: (Media.player?.isPlaying ?? false) && root.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: 14 * Theme.s; duration: 260 + index * 90; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 4 * Theme.s; duration: 300 + index * 70; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }
}
