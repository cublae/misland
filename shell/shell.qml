//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.edges
import qs.notch
import qs.notifications
import qs.services

ShellRoot {
    id: root

    readonly property ShellScreen primaryScreen: {
        const screens = Quickshell.screens;
        return screens.find(s => s.name === Config.screen) ?? screens[0] ?? null;
    }

    Loader {
        active: root.primaryScreen !== null

        sourceComponent: Notch {
            screen: root.primaryScreen
        }
    }

    Loader {
        active: root.primaryScreen !== null

        sourceComponent: Popups {
            screen: root.primaryScreen
        }
    }

    Loader {
        active: root.primaryScreen !== null && Config.edges.workspaces

        sourceComponent: CornerPanel {
            id: workspacesPanel

            screen: root.primaryScreen
            WlrLayershell.namespace: "misland-workspaces"

            Workspaces {}

            // Pops out on workspace switches. The first value at startup is
            // not a switch, so wait a moment before reacting.
            property bool ready: false
            Timer {
                running: true
                interval: 1500
                onTriggered: workspacesPanel.ready = true
            }
            Connections {
                target: Hyprland
                enabled: workspacesPanel.ready && Config.edges.showOnSwitch
                function onFocusedWorkspaceChanged() { workspacesPanel.peek(Config.edges.showOnSwitchMs); }
            }
        }
    }

    Loader {
        active: root.primaryScreen !== null && Config.edges.tray

        sourceComponent: CornerPanel {
            id: trayPanel

            screen: root.primaryScreen
            rightSide: true
            overhang: 44 * Theme.s
            keepOpen: tray.menuOpen
            WlrLayershell.namespace: "misland-tray"

            Tray {
                id: tray
                window: trayPanel
            }
        }
    }

    IpcHandler {
        target: "notch"

        function toggle(): void { NotchState.toggle("panel"); }
        function open(): void { NotchState.show("panel"); }
        function close(): void { NotchState.close(); }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void { NotchState.toggle("launcher"); }
        function open(): void { NotchState.show("launcher"); }
        function close(): void { NotchState.close(); }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void { NotchState.toggle("clipboard"); }
        function open(): void { NotchState.show("clipboard"); }
        function close(): void { NotchState.close(); }
    }

    IpcHandler {
        target: "color"

        function pick(): void { ColorPicker.pick(); }
    }
}
