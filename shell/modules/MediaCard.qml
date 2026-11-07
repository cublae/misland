import QtQuick
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

Card {
    id: root

    readonly property var player: Media.player
    readonly property real progress: player && player.length > 0 ? player.position / player.length : 0

    implicitHeight: 124 * Theme.s

    // Empty state.
    Row {
        anchors.centerIn: parent
        spacing: 8 * Theme.s
        visible: !root.player

        Icon {
            name: "music_note"
            color: Theme.textDim
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: "Nothing playing"
            color: Theme.textDim
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: root.padding
        visible: root.player !== null

        ClippingRectangle {
            id: cover

            width: 64 * Theme.s
            height: width
            radius: 12 * Theme.s
            color: Theme.track

            Icon {
                anchors.centerIn: parent
                name: "music_note"
                size: 28 * Theme.s
                color: Theme.textDim
                visible: art.status !== Image.Ready
            }

            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: width * 2
                sourceSize.height: height * 2
            }
        }

        Column {
            anchors.left: cover.right
            anchors.leftMargin: 12 * Theme.s
            anchors.right: controls.left
            anchors.rightMargin: 8 * Theme.s
            anchors.verticalCenter: cover.verticalCenter
            spacing: 2 * Theme.s

            Label {
                width: parent.width
                text: root.player?.trackTitle || "Unknown title"
                size: 14
                font.weight: Font.DemiBold
            }
            Label {
                width: parent.width
                text: root.player?.trackArtist || root.player?.identity || ""
                size: 12
                color: Theme.textDim
            }
            Label {
                width: parent.width
                text: root.player?.identity ?? ""
                size: 10
                color: Theme.textFaint
                visible: Media.players.length > 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.next()
                }
            }
        }

        Row {
            id: controls

            anchors.right: parent.right
            anchors.verticalCenter: cover.verticalCenter

            IconButton {
                icon: "skip_previous"
                filled: true
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }
            IconButton {
                icon: root.player?.isPlaying ? "pause" : "play_arrow"
                filled: true
                iconSize: 26 * Theme.s
                implicitWidth: 38 * Theme.s
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player.togglePlaying()
            }
            IconButton {
                icon: "skip_next"
                filled: true
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
        }

        // Progress: elapsed, bar, total.
        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 14 * Theme.s
            visible: (root.player?.length ?? 0) > 0

            Label {
                id: elapsed
                anchors.verticalCenter: parent.verticalCenter
                text: Media.formatTime(root.player?.position ?? 0)
                size: 10
                color: Theme.textDim
                font.features: { "tnum": 1 }
            }

            Rectangle {
                id: bar
                anchors.left: elapsed.right
                anchors.right: total.left
                anchors.margins: 8 * Theme.s
                anchors.verticalCenter: parent.verticalCenter
                height: 4 * Theme.s
                radius: height / 2
                color: Theme.track

                Rectangle {
                    width: parent.width * Math.min(1, root.progress)
                    height: parent.height
                    radius: parent.radius
                    color: Theme.text
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6 * Theme.s
                    enabled: root.player?.canSeek ?? false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        root.player.position = Math.max(0, Math.min(1, (mouse.x - 6 * Theme.s) / bar.width)) * root.player.length;
                    }
                }
            }

            Label {
                id: total
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Media.formatTime(root.player?.length ?? 0)
                size: 10
                color: Theme.textDim
                font.features: { "tnum": 1 }
            }
        }
    }
}
