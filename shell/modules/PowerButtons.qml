import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.notch
import qs.services

// Lock, suspend, log out, reboot, power off. The last three ask for a
// second click within three seconds before they run.
Row {
    id: root

    spacing: 2 * Theme.s

    property string armed: ""

    function run(action: string, confirm: bool): void {
        if (confirm && armed !== action) {
            armed = action;
            disarm.restart();
            return;
        }
        armed = "";
        NotchState.close();
        const command = Config.power[action];
        if (action === "logout" && command.length === 0) Hypr.exit();
        else Quickshell.execDetached(command);
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    // Confirmation hint, shown left of the buttons.
    Label {
        anchors.verticalCenter: parent.verticalCenter
        rightPadding: 6 * Theme.s
        text: root.armed ? `Click again to ${root.armed === "poweroff" ? "power off" : root.armed === "logout" ? "log out" : root.armed}` : ""
        size: 11
        color: Theme.danger
        opacity: root.armed ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Repeater {
        model: [
            { action: "lock", icon: "lock", confirm: false },
            { action: "suspend", icon: "bedtime", confirm: false },
            { action: "logout", icon: "logout", confirm: true },
            { action: "reboot", icon: "restart_alt", confirm: true },
            { action: "poweroff", icon: "power_settings_new", confirm: true }
        ]

        IconButton {
            required property var modelData
            readonly property bool isArmed: root.armed === modelData.action

            icon: modelData.icon
            iconSize: 19 * Theme.s
            iconColor: isArmed ? Theme.text : Theme.textDim
            highlighted: isArmed
            highlightColor: Theme.danger
            onClicked: root.run(modelData.action, modelData.confirm)
        }
    }
}
