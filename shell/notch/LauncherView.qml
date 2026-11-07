import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// App launcher shown in the notch: type to search, arrows to move,
// Enter to launch, Esc to close.
FocusScope {
    id: root

    readonly property real rowHeight: 46 * Theme.s
    readonly property int shown: Math.min(results.length, Config.launcher.maxResults)
    property list<DesktopEntry> results: Apps.search(input.text)
    property int current: 0

    implicitWidth: 560 * Theme.s
    implicitHeight: field.height + (shown > 0 ? Theme.gap + list.height : 0)

    function reset(): void {
        input.text = "";
        current = 0;
    }

    function move(delta: int): void {
        if (results.length === 0) return;
        current = (current + delta + results.length) % results.length;
        list.positionViewAtIndex(current, ListView.Contain);
    }

    function launch(index: int): void {
        const e = results[index];
        if (!e) return;
        NotchState.close();
        Apps.launch(e);
    }

    onResultsChanged: {
        current = 0;
        list.positionViewAtBeginning();
    }

    Connections {
        target: NotchState
        function onLauncherChanged() { if (NotchState.launcher) root.reset(); }
    }

    Card {
        id: field

        width: parent.width
        height: 46 * Theme.s

        Icon {
            id: searchIcon
            x: 14 * Theme.s
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            color: Theme.textDim
        }

        TextInput {
            id: input

            // Takes the keyboard as soon as the notch window has it. Asking for
            // focus explicitly (forceActiveFocus) breaks the Hyprland focus grab.
            focus: true

            anchors.left: searchIcon.right
            anchors.leftMargin: 10 * Theme.s
            anchors.right: parent.right
            anchors.rightMargin: 14 * Theme.s
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            selectionColor: Theme.accent
            font.family: Theme.font
            font.pixelSize: 16 * Theme.s
            clip: true

            Keys.onDownPressed: root.move(1)
            Keys.onUpPressed: root.move(-1)
            Keys.onTabPressed: root.move(1)
            Keys.onBacktabPressed: root.move(-1)
            Keys.onReturnPressed: root.launch(root.current)
            Keys.onEnterPressed: root.launch(root.current)
            Keys.onEscapePressed: NotchState.close()

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: "Search apps"
                size: 16
                color: Theme.textFaint
                visible: input.text === ""
            }
        }
    }

    ListView {
        id: list

        y: field.height + Theme.gap
        width: parent.width
        height: root.shown * root.rowHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.results
        currentIndex: root.current
        highlightMoveDuration: 0
        visible: root.shown > 0

        highlight: Rectangle {
            radius: 12 * Theme.s
            color: Theme.surfaceHover
        }

        delegate: Item {
            id: row

            required property DesktopEntry modelData
            required property int index

            width: list.width
            height: root.rowHeight

            Image {
                id: appIcon
                x: 10 * Theme.s
                anchors.verticalCenter: parent.verticalCenter
                width: 30 * Theme.s
                height: width
                source: Apps.icon(row.modelData)
                sourceSize.width: width * 2
                sourceSize.height: height * 2
                asynchronous: true
            }

            Column {
                anchors.left: appIcon.right
                anchors.leftMargin: 12 * Theme.s
                anchors.right: parent.right
                anchors.rightMargin: 12 * Theme.s
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    width: parent.width
                    text: row.modelData.name
                    size: 14
                    font.weight: Font.DemiBold
                }
                Label {
                    width: parent.width
                    text: row.modelData.comment || row.modelData.genericName
                    size: 11
                    color: Theme.textDim
                    visible: text !== ""
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.current = row.index
                onClicked: root.launch(row.index)
            }
        }
    }
}
