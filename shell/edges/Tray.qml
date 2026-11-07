import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.config

// Horizontal system tray, dropped from the top edge. Left click activates
// (or opens the menu for menu-only items), right click opens the menu,
// middle click is the secondary action, scrolling is passed to the item.
Row {
    id: root

    required property var window
    readonly property bool menuOpen: menu.visible
    readonly property real cell: 26 * Theme.s

    spacing: 4 * Theme.s

    QsMenuAnchor {
        id: menu

        anchor.window: root.window
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
    }

    function openMenu(item: SystemTrayItem, cell: Item): void {
        const pos = cell.mapToItem(null, 0, 0);
        menu.menu = item.menu;
        menu.anchor.rect = Qt.rect(pos.x, pos.y + cell.height + 10 * Theme.s, cell.width, 1);
        menu.open();
    }

    Label {
        visible: SystemTray.items.values.length === 0
        width: 120 * Theme.s
        height: root.cell
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: "Tray is empty"
        size: 12
        color: Theme.textDim
    }

    Repeater {
        model: SystemTray.items

        Rectangle {
            id: cell

            required property SystemTrayItem modelData

            width: root.cell
            height: root.cell
            radius: height / 2
            color: area.containsMouse ? Theme.surfaceHover : "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16 * Theme.s
                source: cell.modelData.icon
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: mouse => {
                    const item = cell.modelData;
                    if (mouse.button === Qt.MiddleButton) item.secondaryActivate();
                    else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu) root.openMenu(item, cell);
                    } else item.activate();
                }
                onWheel: wheel => cell.modelData.scroll(wheel.angleDelta.y, false)
            }

            // Name of the app, shown below the panel while hovered.
            Rectangle {
                anchors.top: parent.bottom
                anchors.topMargin: 12 * Theme.s
                anchors.horizontalCenter: parent.horizontalCenter
                visible: area.containsMouse && !root.menuOpen && tip.text !== ""
                width: tip.implicitWidth + 16 * Theme.s
                height: 24 * Theme.s
                radius: height / 2
                color: Theme.background
                border.width: 1
                border.color: Theme.track

                Label {
                    id: tip
                    anchors.centerIn: parent
                    text: cell.modelData.tooltipTitle || cell.modelData.title || cell.modelData.id
                    size: 11
                }
            }
        }
    }
}
