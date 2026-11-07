import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.edges
import qs.notch
import qs.services

// Notification popups in a black corner panel that slides out of the
// top-right screen corner to the left (←). New notifications stack inside it
// and the panel springs to its new height; when the last one goes, the panel
// slides back into the corner.
PanelWindow {
    id: win

    readonly property real s: Theme.s
    readonly property real pad: 8 * s
    readonly property real cardWidth: 360 * s

    // Lowered while the last popup leaves, so the panel slides out with it.
    property bool closing: false
    readonly property bool shown: Notifications.popups.count > 0 && !closing

    anchors.top: true
    anchors.right: true
    // Room on the left for the spring to overshoot.
    implicitWidth: shape.width + 24 * s
    implicitHeight: Math.max(1, shape.height)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // Bound to the model rather than to the view: views in a hidden window
    // do not update, so they could never make it visible.
    visible: Notifications.popups.count > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "misland-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region { item: slider }

    Connections {
        target: Notifications.popups
        function onCountChanged() { if (Notifications.popups.count > 0) win.closing = false; }
    }

    Item {
        id: slider

        width: shape.width
        height: shape.height
        // Rests in the corner when shown, hidden past the right edge otherwise.
        x: win.shown ? win.width - width : win.width + 2

        Behavior on x { NotchSpring {} }

        // Fills the gap at the screen edge while the spring overshoots.
        Rectangle {
            x: shape.width - 1
            width: 48 * win.s
            height: shape.bodyHeight
            color: Theme.background
        }

        CornerShape {
            id: shape

            mirrored: true
            color: Theme.background
            bodyWidth: win.cardWidth + 2 * win.pad
            bodyHeight: column.implicitHeight + 2 * win.pad
            radius: 22 * win.s
            ear: 12 * win.s

            Behavior on bodyHeight {
                enabled: win.shown
                NotchSpring {}
            }
        }

        Column {
            id: column

            // The body sits in the corner; the ear sticks out on the left.
            x: shape.e + win.pad
            y: win.pad
            width: win.cardWidth
            spacing: 2 * win.s

            Repeater {
                model: Notifications.popups

                delegate: Item {
                    id: slot

                    required property int nid
                    readonly property var notification: Notifications.find(nid)
                    property bool leaving: false
                    // Closed by the user: dismiss for good once the animation is done.
                    property bool dismissAfter: false

                    function finish(): void {
                        if (dismissAfter) notification?.dismiss();
                        else Notifications.hidePopup(nid);
                    }

                    width: column.width
                    height: card.height

                    // The last popup leaves with the panel; others fade out.
                    function leave(): void {
                        if (leaving) return;
                        leaving = true;
                        if (Notifications.popups.count === 1) {
                            win.closing = true;
                            removeLater.start();
                        } else {
                            fade.start();
                        }
                    }

                    Timer {
                        id: removeLater
                        interval: 450
                        onTriggered: slot.finish()
                    }

                    NumberAnimation {
                        id: fade
                        target: card
                        property: "opacity"
                        to: 0
                        duration: 200
                        onFinished: slot.finish()
                    }

                    NotificationCard {
                        id: card

                        width: parent.width
                        notification: slot.notification
                        onCloseRequested: {
                            slot.dismissAfter = true;
                            slot.leave();
                        }

                        opacity: 0
                        Component.onCompleted: appear.start()

                        NumberAnimation on opacity {
                            id: appear
                            running: false
                            to: 1
                            duration: 250
                        }
                    }

                    Timer {
                        readonly property real seconds: slot.notification?.expireTimeout > 0
                            ? Math.min(slot.notification.expireTimeout, 60) : Config.notifications.timeout

                        interval: seconds * 1000
                        running: !card.hovered && !slot.leaving && card.notification !== null && !card.critical
                        onTriggered: slot.leave()
                    }
                }
            }
        }
    }
}
