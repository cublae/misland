import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Clipboard history shown in the notch: type to filter, arrows to move,
// Enter to copy the entry back, Delete to remove it, Esc to close.
FocusScope {
    id: root

    readonly property real rowHeight: 48 * Theme.s
    readonly property int maxRows: 7
    readonly property int shown: Math.min(results.length, maxRows)
    property var results: Clipboard.search(input.text)
    property int current: 0

    implicitWidth: 560 * Theme.s
    implicitHeight: field.height + Theme.gap + (shown > 0 ? list.height : empty.height)

    function reset(): void {
        input.text = "";
        current = 0;
        Clipboard.refresh();
    }

    function move(delta: int): void {
        if (results.length === 0) return;
        current = (current + delta + results.length) % results.length;
        list.positionViewAtIndex(current, ListView.Contain);
    }

    function pick(index: int): void {
        const e = results[index];
        if (!e) return;
        NotchState.close();
        Clipboard.copy(e);
    }

    function remove(index: int): void {
        const e = results[index];
        if (!e) return;
        Clipboard.remove(e);
        current = Math.min(current, results.length - 1);
    }

    onResultsChanged: {
        current = Math.min(current, Math.max(0, results.length - 1));
        if (input.text !== "") {
            current = 0;
            list.positionViewAtBeginning();
        }
    }

    Connections {
        target: NotchState
        function onClipboardChanged() { if (NotchState.clipboard) root.reset(); }
    }

    Card {
        id: field

        width: parent.width
        height: 46 * Theme.s

        Icon {
            id: searchIcon
            x: 14 * Theme.s
            anchors.verticalCenter: parent.verticalCenter
            name: "content_paste_search"
            color: Theme.textDim
        }

        TextInput {
            id: input

            // Takes the keyboard as soon as the notch window has it. Asking for
            // focus explicitly (forceActiveFocus) breaks the Hyprland focus grab.
            focus: true

            anchors.left: searchIcon.right
            anchors.leftMargin: 10 * Theme.s
            anchors.right: clear.left
            anchors.rightMargin: 10 * Theme.s
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
            Keys.onReturnPressed: root.pick(root.current)
            Keys.onEnterPressed: root.pick(root.current)
            Keys.onEscapePressed: NotchState.close()
            Keys.onDeletePressed: event => {
                // Delete edits the query while there is text after the cursor.
                if (cursorPosition < text.length) event.accepted = false;
                else root.remove(root.current);
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: "Search clipboard"
                size: 16
                color: Theme.textFaint
                visible: input.text === ""
            }
        }

        Rectangle {
            id: clear

            anchors.right: parent.right
            anchors.rightMargin: 8 * Theme.s
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: clearLabel.implicitWidth + 18 * Theme.s
            implicitHeight: 28 * Theme.s
            radius: height / 2
            color: clearArea.containsMouse ? Theme.track : "transparent"
            visible: Clipboard.entries.length > 0

            Label {
                id: clearLabel
                anchors.centerIn: parent
                text: "Clear all"
                size: 11
                color: Theme.textDim
            }

            MouseArea {
                id: clearArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Clipboard.wipe()
            }
        }
    }

    Label {
        id: empty

        y: field.height + Theme.gap
        width: parent.width
        height: 40 * Theme.s
        visible: root.shown === 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Clipboard.entries.length === 0 ? "Clipboard history is empty" : "Nothing matches"
        size: 13
        color: Theme.textDim
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

            required property var modelData
            required property int index
            readonly property var entry: modelData

            width: list.width
            height: root.rowHeight

            // Text entries get an icon; images a thumbnail decoded on demand.
            Item {
                id: lead

                x: 10 * Theme.s
                anchors.verticalCenter: parent.verticalCenter
                width: (row.entry.image ? 40 : 24) * Theme.s
                height: row.entry.image ? 36 * Theme.s : width

                Icon {
                    anchors.centerIn: parent
                    visible: !row.entry.image || thumb.status !== Image.Ready
                    name: row.entry.image ? "image" : /^https?:\/\//.test(row.entry.text) ? "link" : "notes"
                    color: Theme.textDim
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: 6 * Theme.s
                    color: "transparent"
                    visible: thumb.status === Image.Ready

                    Image {
                        id: thumb
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: width * 2
                        sourceSize.height: height * 2
                    }
                }

                Process {
                    running: row.entry.image
                    command: ["sh", "-c",
                        'f="$1"; [ -s "$f" ] || { mkdir -p "${f%/*}" && printf "%s" "$2" | cliphist decode > "$f"; }',
                        "sh", Clipboard.thumbnailPath(row.entry), row.entry.line]
                    onExited: thumb.source = "file://" + Clipboard.thumbnailPath(row.entry)
                }
            }

            Label {
                anchors.left: lead.right
                anchors.leftMargin: 12 * Theme.s
                anchors.right: remove.left
                anchors.rightMargin: 8 * Theme.s
                anchors.verticalCenter: parent.verticalCenter
                // One line: newlines and runs of spaces collapse.
                text: row.entry.text.replace(/\s+/g, " ").trim()
                textFormat: Text.PlainText
                size: 13
                color: row.entry.image ? Theme.textDim : Theme.text
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.current = row.index
                onClicked: root.pick(row.index)
            }

            IconButton {
                id: remove

                anchors.right: parent.right
                anchors.rightMargin: 8 * Theme.s
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 28 * Theme.s
                icon: "delete"
                iconSize: 17 * Theme.s
                iconColor: Theme.textDim
                visible: root.current === row.index
                onClicked: root.remove(row.index)
            }
        }
    }
}
