import QtQuick
import QtQuick.Shapes

// Corner piece for the top-left screen corner: a body flush with the top and
// left edges, a rounded free corner, and a concave ear where it meets the top
// edge. Set `mirrored` for the top-right corner.
//
//   ┌────────────╮_       top edge, with the ear
//   │   body     │
//   └────────────╯        flat along the side edge
Shape {
    id: root

    property real bodyWidth: 200
    property real bodyHeight: 40
    property real radius: 18
    property real ear: 12
    property bool mirrored: false
    property color color: "black"

    readonly property real r: Math.max(0, Math.min(radius, bodyHeight / 2, bodyWidth / 2))
    readonly property real e: Math.max(0, Math.min(ear, bodyHeight - r))
    readonly property real w: bodyWidth
    readonly property real h: bodyHeight

    width: w + e
    height: h
    preferredRendererType: Shape.CurveRenderer

    transform: Scale {
        xScale: root.mirrored ? -1 : 1
        origin.x: root.width / 2
    }

    ShapePath {
        fillColor: root.color
        strokeWidth: -1

        startX: 0
        startY: 0

        PathLine { x: root.w + root.e; y: 0 }
        // Ear along the top edge.
        PathArc {
            x: root.w; y: root.e
            radiusX: root.e; radiusY: root.e
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.w; y: root.h - root.r }
        // Free corner.
        PathArc { x: root.w - root.r; y: root.h; radiusX: root.r; radiusY: root.r }
        PathLine { x: 0; y: root.h }
        PathLine { x: 0; y: 0 }
    }
}
