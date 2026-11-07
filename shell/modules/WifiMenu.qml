import QtQuick
import Quickshell.Networking
import qs.components
import qs.config
import qs.services

// Wi-Fi networks, strongest first with the current one on top. Click to
// connect or disconnect; secured networks that are not saved ask for a
// password inline. Scans while open.
Card {
    id: root

    required property var device   // WifiDevice
    readonly property real maxListHeight: 200 * Theme.s

    // Network waiting for a password, and the last failure message.
    property var askingFor: null
    property string error: ""

    readonly property var networks: (device?.networks.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    function signalIcon(n: var): string {
        return n.signalStrength > 0.66 ? "wifi" : n.signalStrength > 0.33 ? "wifi_2_bar" : "wifi_1_bar";
    }

    function secured(n: var): bool {
        return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe;
    }

    function activate(n: var): void {
        error = "";
        if (n.connected) n.disconnect();
        else if (n.known || !secured(n)) n.connect();
        else {
            askingFor = n;
            password.text = "";
            // Not forceActiveFocus(): that asks Hyprland to activate the window
            // and breaks the focus grab that keeps the notch open.
            password.focus = true;
        }
    }

    implicitHeight: content.implicitHeight + 2 * padding

    Binding {
        target: root.device
        property: "scannerEnabled"
        value: true
        when: root.device !== null && root.visible
    }

    Column {
        id: content

        x: root.padding / 2
        y: root.padding
        width: parent.width - root.padding
        spacing: 2 * Theme.s

        Label {
            leftPadding: 8 * Theme.s
            bottomPadding: 4 * Theme.s
            text: !Networking.wifiEnabled ? "Wi-Fi is off" : root.networks.length === 0 ? "Searching…" : "Networks"
            size: 11
            color: Theme.textDim
        }

        Flickable {
            width: parent.width
            height: Math.min(list.implicitHeight, root.maxListHeight)
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: Networking.wifiEnabled

            Column {
                id: list
                width: parent.width

                Repeater {
                    model: root.networks

                    ListRow {
                        required property var modelData
                        readonly property var n: modelData

                        width: list.width
                        icon: root.signalIcon(n)
                        iconFilled: n.connected
                        title: n.name
                        active: n.connected
                        busy: n.stateChanging
                        status: n.state === ConnectionState.Connecting ? "Connecting…"
                            : n.state === ConnectionState.Disconnecting ? "Disconnecting…"
                            : n.connected ? "Connected"
                            : n.known ? "Saved"
                            : root.secured(n) ? "" : "Open"
                        onClicked: root.activate(n)

                        Connections {
                            target: n
                            function onConnectionFailed(reason) {
                                root.error = `Could not connect to ${n.name}`;
                                if (root.secured(n)) root.askingFor = n;
                            }
                        }
                    }
                }
            }
        }

        // Password prompt for the chosen network.
        Rectangle {
            width: parent.width
            height: 36 * Theme.s
            radius: 10 * Theme.s
            color: Theme.track
            visible: root.askingFor !== null

            Icon {
                id: lock
                x: 8 * Theme.s
                anchors.verticalCenter: parent.verticalCenter
                name: "lock"
                size: 18 * Theme.s
                color: Theme.textDim
            }

            TextInput {
                id: password

                anchors.left: lock.right
                anchors.leftMargin: 10 * Theme.s
                anchors.right: parent.right
                anchors.rightMargin: 10 * Theme.s
                anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 13 * Theme.s
                clip: true

                Keys.onReturnPressed: submit()
                Keys.onEnterPressed: submit()
                Keys.onEscapePressed: root.askingFor = null

                function submit(): void {
                    if (!root.askingFor || text === "") return;
                    root.error = "";
                    root.askingFor.connectWithPsk(text);
                    root.askingFor = null;
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: password.text === ""
                    text: `Password for ${root.askingFor?.name ?? ""}`
                    size: 13
                    color: Theme.textFaint
                }
            }
        }

        Label {
            leftPadding: 8 * Theme.s
            visible: root.error !== ""
            text: root.error
            size: 11
            color: Theme.danger
        }
    }
}
