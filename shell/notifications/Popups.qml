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
    // Fixed size, mapped once at startup: resizing a layer surface on every
    // animation frame (or mapping it when the first popup arrives) stutters.
    // Only the panel inside moves; the mask keeps the rest click-through.
    // Width leaves room on the left for the spring to overshoot.
    implicitWidth: Math.ceil(cardWidth + 2 * pad + 12 * s + 24 * s)
    implicitHeight: Math.ceil((screen?.height ?? 1080) * 0.85)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

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

        // Clips the cards to the panel's current, animated size, so text never
        // shows outside the black background while the panel grows.
        Item {
            // The body sits in the corner; the ear sticks out on the left.
            x: shape.e
            width: shape.bodyWidth
            height: shape.bodyHeight
            clip: true

            Column {
                id: column

                x: win.pad
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
                            // expireTimeout comes in milliseconds, as on D-Bus; cap it at a minute.
                            interval: slot.notification?.expireTimeout > 0
                                ? Math.min(slot.notification.expireTimeout, 60000)
                                : Config.notifications.timeout * 1000
                            running: !card.hovered && !slot.leaving && card.notification !== null && !card.critical
                            onTriggered: slot.leave()
                        }
                    }
                }
            }
        }
    }
}
