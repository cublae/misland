import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: win

    // Sizes are designed for 1080 logical px of height and scale from there.
    readonly property real s: Math.max(0.8, Math.min(1.6, screen.height / 1080)) * Config.scale
    readonly property bool expanded: NotchState.expanded
    readonly property bool hovered: mouse.containsMouse
    readonly property bool launcher: NotchState.launcher
    readonly property bool clipboard: NotchState.clipboard
    readonly property bool open: NotchState.open
    readonly property bool showingActivity: !open && Activity.current !== null

    readonly property real collapsedHeight: Theme.barHeight
    readonly property real collapsedWidth: Math.max(180 * s, collapsed.implicitWidth + 36 * s)
    readonly property real activityWidth: Math.max(collapsedWidth, activityView.implicitWidth + 36 * s)
    readonly property real activityHeight: Math.max(collapsedHeight, activityView.implicitHeight + 14 * s)
    readonly property real padding: 18 * s
    readonly property real expandedWidth: expandedView.implicitWidth + 2 * padding
    readonly property real expandedHeight: expandedView.implicitHeight + 2 * padding
    readonly property real launcherWidth: launcherView.implicitWidth + 2 * padding
    readonly property real launcherHeight: launcherView.implicitHeight + 2 * padding
    readonly property real clipboardWidth: clipboardView.implicitWidth + 2 * padding
    readonly property real clipboardHeight: clipboardView.implicitHeight + 2 * padding

    // Room for the spring to overshoot without hitting the window edge.
    readonly property real overshoot: 1.12

    anchors.top: true
    implicitWidth: Math.ceil((Math.max(expandedWidth, launcherWidth, clipboardWidth) + 2 * 16 * s) * overshoot)
    implicitHeight: Math.ceil(Math.max(expandedHeight, launcherHeight, clipboardHeight) * overshoot)
    color: "transparent"

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Config.reserveSpace ? collapsedHeight : 0

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "misland-notch"
    // OnDemand, not Exclusive: an exclusive layer breaks the focus grab
    // below, which then collapses the notch at once. The grab itself hands
    // the keyboard to the notch, so the launcher can be typed into right away.
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Only the notch itself takes input; the rest of the window is click-through.
    mask: Region { item: shape }

    Binding {
        target: Theme
        property: "s"
        value: win.s
    }

    // Clicking anywhere outside the notch collapses it.
    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: NotchState.close()
    }

    NotchShape {
        id: shape

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        color: Theme.background

        bodyWidth: win.launcher ? win.launcherWidth
            : win.clipboard ? win.clipboardWidth
            : win.expanded ? win.expandedWidth
            : win.showingActivity ? win.activityWidth
            : win.collapsedWidth + (win.hovered ? 10 * win.s : 0)
        bodyHeight: win.launcher ? win.launcherHeight
            : win.clipboard ? win.clipboardHeight
            : win.expanded ? win.expandedHeight
            : win.showingActivity ? win.activityHeight
            : win.collapsedHeight + (win.hovered ? 3 * win.s : 0)
        radius: (win.open ? 36 : 12) * win.s
        ear: (win.open ? 16 : 8) * win.s

        Behavior on bodyWidth { NotchSpring {} }
        Behavior on bodyHeight { NotchSpring {} }
        Behavior on radius { NotchSpring {} }
        Behavior on ear { NotchSpring {} }

        MouseArea {
            id: mouse

            x: shape.e
            width: shape.bodyWidth
            // When expanded, only the header row closes the notch so the
            // modules below can handle their own clicks.
            height: win.launcher || win.clipboard ? 0
                : win.expanded ? win.padding + expandedView.headerHeight : shape.bodyHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NotchState.toggle("panel")
        }

        FocusScope {
            id: body

            x: shape.e
            width: shape.bodyWidth
            height: shape.bodyHeight
            clip: true
            focus: true

            Keys.onEscapePressed: NotchState.close()

            CollapsedView {
                id: collapsed

                readonly property bool shown: !win.open && !win.showingActivity

                anchors.horizontalCenter: parent.horizontalCenter
                y: (win.collapsedHeight - implicitHeight) / 2
                opacity: shown ? 1 : 0
                scale: shown ? 1 : 0.85

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            LiveActivity {
                id: activityView

                // Keep the last activity while it fades out.
                Connections {
                    target: Activity
                    function onCurrentChanged() {
                        if (Activity.current) activityView.activity = Activity.current;
                    }
                }

                anchors.horizontalCenter: parent.horizontalCenter
                y: (win.activityHeight - implicitHeight) / 2
                opacity: win.showingActivity ? 1 : 0
                visible: opacity > 0
                scale: win.showingActivity ? 1 : 0.85

                Behavior on opacity {
                    NumberAnimation {
                        duration: win.showingActivity ? 220 : 120
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            }

            LauncherView {
                id: launcherView

                focus: win.launcher

                anchors.horizontalCenter: parent.horizontalCenter
                y: win.padding
                opacity: win.launcher ? 1 : 0
                visible: opacity > 0
                scale: win.launcher ? 1 : 0.92
                transformOrigin: Item.Top

                Behavior on opacity {
                    NumberAnimation {
                        duration: win.launcher ? 220 : 100
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }

            ClipboardView {
                id: clipboardView

                focus: win.clipboard

                anchors.horizontalCenter: parent.horizontalCenter
                y: win.padding
                opacity: win.clipboard ? 1 : 0
                visible: opacity > 0
                scale: win.clipboard ? 1 : 0.92
                transformOrigin: Item.Top

                Behavior on opacity {
                    NumberAnimation {
                        duration: win.clipboard ? 220 : 100
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }

            ExpandedView {
                id: expandedView

                anchors.horizontalCenter: parent.horizontalCenter
                y: win.padding
                opacity: win.expanded ? 1 : 0
                visible: opacity > 0
                scale: win.expanded ? 1 : 0.92
                transformOrigin: Item.Top

                Behavior on opacity {
                    NumberAnimation {
                        duration: win.expanded ? 260 : 120
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            }
        }
    }
}
