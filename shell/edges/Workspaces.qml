import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.config
import qs.services

// Horizontal workspace strip: each chip shows the number and the icons of
// its windows. Click to switch, scroll to step through.
Row {
    id: root

    readonly property real chipHeight: 24 * Theme.s
    readonly property int maxIcons: 3

    // Existing workspaces plus the persistent 1..N, sorted by id.
    readonly property var ids: {
        const set = new Set();
        for (let i = 1; i <= Config.edges.persistentWorkspaces; i++) set.add(i);
        for (const w of Hyprland.workspaces.values) if (w.id > 0) set.add(w.id);
        return [...set].sort((a, b) => a - b);
    }

    function workspace(id: int): HyprlandWorkspace {
        return Hyprland.workspaces.values.find(w => w.id === id) ?? null;
    }

    function appIcon(toplevel: HyprlandToplevel): string {
        const id = toplevel.wayland?.appId || toplevel.lastIpcObject?.class || "";
        const entry = DesktopEntries.heuristicLookup(id);
        return Quickshell.iconPath(entry?.icon || id, "application-x-executable");
    }

    spacing: 2 * Theme.s

    Repeater {
        model: root.ids

        Rectangle {
            id: chip

            required property int modelData
            readonly property HyprlandWorkspace ws: root.workspace(modelData)
            readonly property bool active: Hyprland.focusedWorkspace?.id === modelData
            readonly property var windows: ws?.toplevels.values ?? []

            width: content.implicitWidth + 16 * Theme.s
            height: root.chipHeight
            radius: height / 2
            color: active ? Qt.alpha(Theme.accent, 0.22)
                : hover.hovered ? Theme.surfaceHover : "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            HoverHandler { id: hover }

            Row {
                id: content

                anchors.centerIn: parent
                spacing: 6 * Theme.s

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: chip.modelData
                    size: 12
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                    color: chip.active ? Theme.accent : chip.windows.length > 0 ? Theme.text : Theme.textFaint
                }

                Repeater {
                    model: chip.windows.slice(0, root.maxIcons)

                    Item {
                        required property HyprlandToplevel modelData

                        anchors.verticalCenter: parent.verticalCenter
                        width: 16 * Theme.s
                        height: width

                        Image {
                            id: appImage
                            anchors.fill: parent
                            source: root.appIcon(parent.modelData)
                            sourceSize.width: width * 2
                            sourceSize.height: height * 2
                            asynchronous: true
                        }

                        Icon {
                            anchors.centerIn: parent
                            visible: appImage.status === Image.Error
                            name: "web_asset"
                            size: parent.width
                            color: Theme.textDim
                        }
                    }
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: chip.windows.length > root.maxIcons
                    text: `+${chip.windows.length - root.maxIcons}`
                    size: 11
                    color: Theme.textDim
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.focusWorkspace(chip.modelData)
            }
        }
    }

    WheelHandler {
        onWheel: event => Hypr.focusWorkspace(event.angleDelta.y > 0 ? "r-1" : "r+1")
    }
}
