//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.edges
import qs.notch
import qs.notifications

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
            screen: root.primaryScreen
            WlrLayershell.namespace: "misland-workspaces"

            Workspaces {}
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

        function toggle(): void { NotchState.expanded = !NotchState.expanded; }
        function open(): void { NotchState.expanded = true; }
        function close(): void { NotchState.close(); }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void { NotchState.launcher = !NotchState.launcher; }
        function open(): void { NotchState.launcher = true; }
        function close(): void { NotchState.close(); }
    }
}
