import QtQuick
import QtQuick.Shapes

// Notch silhouette: a body hanging from the top edge with rounded bottom
// corners and concave "ears" where it meets the screen edge, like the
// MacBook cut-out. Total width is bodyWidth + 2 * ear.
Shape {
    id: root

    property real bodyWidth: 200
    property real bodyHeight: 32
    property real radius: 12
    property real ear: 8
    property color color: "black"

    readonly property real r: Math.max(0, Math.min(radius, bodyHeight / 2, bodyWidth / 2))
    readonly property real e: Math.max(0, Math.min(ear, bodyHeight - r))
    readonly property real rightEdge: e + bodyWidth

    width: bodyWidth + 2 * e
    height: bodyHeight
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        strokeWidth: -1

        startX: 0
        startY: 0

        // Left ear, curving from the screen edge down into the body.
        PathArc { x: root.e; y: root.e; radiusX: root.e; radiusY: root.e }
        PathLine { x: root.e; y: root.bodyHeight - root.r }
        PathArc {
            x: root.e + root.r; y: root.bodyHeight
            radiusX: root.r; radiusY: root.r
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.rightEdge - root.r; y: root.bodyHeight }
        PathArc {
            x: root.rightEdge; y: root.bodyHeight - root.r
            radiusX: root.r; radiusY: root.r
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.rightEdge; y: root.e }
        // Right ear.
        PathArc { x: root.rightEdge + root.e; y: 0; radiusX: root.e; radiusY: root.e }
        PathLine { x: 0; y: 0 }
    }
}
