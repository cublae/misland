import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.notch

// Slides sideways out of a top screen corner while the pointer touches the
// top edge near that corner: from the left corner to the right (→), from the
// right corner to the left (←). Slides back once the pointer leaves.
// Everything except the hover strip and the panel itself is click-through.
PanelWindow {
    id: win

    property bool rightSide: false
    // Hold the panel open, e.g. while one of its menus is showing.
    property bool keepOpen: false
    // Extra height below the panel for things drawn under it (tooltips).
    property real overhang: 0
    default property alias content: holder.data
    readonly property bool shown: hovering || keepOpen || peeking

    property bool hovering: false
    property bool peeking: false

    // Show the panel for `ms` milliseconds without the pointer, e.g. when the
    // workspace changes. Hovering it meanwhile keeps it open.
    function peek(ms: int): void {
        peeking = true;
        peekTimer.interval = ms;
        peekTimer.restart();
    }

    Timer {
        id: peekTimer
        onTriggered: win.peeking = false
    }

    readonly property real s: Theme.s
    readonly property real pad: 10 * s
    readonly property real stripLength: (screen?.width ?? 1920) * Config.edges.triggerLength

    anchors.top: true
    anchors.left: !rightSide
    anchors.right: rightSide
    // Room for the spring to overshoot past its resting place.
    implicitWidth: Math.max(stripLength, shape.width + 24 * s)
    implicitHeight: shape.height + overhang
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region { item: win.shown ? openArea : trigger }

    Timer {
        id: openDelay
        // Short delay so sweeping along the edge does not pop the panel.
        interval: 90
        onTriggered: win.hovering = true
    }

    Timer {
        id: closeDelay
        interval: 350
        onTriggered: win.hovering = false
    }

    readonly property bool inside: triggerHover.hovered || areaHover.hovered
    onInsideChanged: {
        if (inside) {
            closeDelay.stop();
            if (!hovering) openDelay.restart();
        } else {
            openDelay.stop();
            closeDelay.restart();
        }
    }

    // Hover strip along the top edge, starting at the corner.
    Item {
        id: trigger

        x: win.rightSide ? parent.width - width : 0
        width: win.stripLength
        height: Config.edges.triggerSize

        HoverHandler { id: triggerHover }
    }

    // Strip plus resting panel: keeps the panel open and is the input mask
    // while shown.
    Item {
        id: openArea

        x: win.rightSide ? parent.width - width : 0
        width: Math.max(trigger.width, shape.width)
        height: shape.height

        HoverHandler { id: areaHover }
    }

    Item {
        id: slider

        width: shape.width
        height: shape.height
        // Rests in the corner when shown, hidden past the side edge otherwise.
        x: {
            const offset = win.shown ? 0 : -width - 2;
            return win.rightSide ? win.width - width - offset : offset;
        }

        Behavior on x { NotchSpring {} }

        // Fills the gap at the screen edge while the spring overshoots.
        Rectangle {
            x: win.rightSide ? shape.width - 1 : -width + 1
            width: 48 * win.s
            height: shape.bodyHeight
            color: Theme.background
        }

        CornerShape {
            id: shape

            mirrored: win.rightSide
            color: Theme.background
            bodyWidth: holder.implicitWidth + 2 * win.pad
            // Same height and corners as the collapsed notch.
            bodyHeight: Theme.barHeight
            radius: 12 * win.s
            ear: 8 * win.s
        }

        Item {
            id: holder

            // The body sits in the corner; the ears stick out on the inner side.
            x: (win.rightSide ? shape.e : 0) + win.pad
            y: (shape.bodyHeight - implicitHeight) / 2
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
