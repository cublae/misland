import QtQuick
import QtQuick.Shapes

// Notch silhouette: a body hanging from the top edge with rounded bottom
// corners and concave "ears" where it meets the screen edge, like the
// MacBook cut-out. Total width is w + 2 * ear.
Shape {
    id: root

    property real bodyWidth: 200
    property real bodyHeight: 32
    // Floor for the animated size, so a spring undershoot never makes the
    // notch smaller than its collapsed self.
    property real minWidth: 0
    property real minHeight: 0
    property real radius: 12
    property real ear: 8
    property color color: "black"

    readonly property real w: Math.max(bodyWidth, minWidth)
    readonly property real h: Math.max(bodyHeight, minHeight)
    readonly property real r: Math.max(0, Math.min(radius, h / 2, w / 2))
    readonly property real e: Math.max(0, Math.min(ear, h - r))
    readonly property real rightEdge: e + w

    width: w + 2 * e
    height: h
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        strokeWidth: -1

        startX: 0
        startY: 0

        // Left ear, curving from the screen edge down into the body.
        PathArc { x: root.e; y: root.e; radiusX: root.e; radiusY: root.e }
        PathLine { x: root.e; y: root.h - root.r }
        PathArc {
            x: root.e + root.r; y: root.h
            radiusX: root.r; radiusY: root.r
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.rightEdge - root.r; y: root.h }
        PathArc {
            x: root.rightEdge; y: root.h - root.r
            radiusX: root.r; radiusY: root.r
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.rightEdge; y: root.e }
        // Right ear.
        PathArc { x: root.rightEdge + root.e; y: 0; radiusX: root.e; radiusY: root.e }
        PathLine { x: 0; y: 0 }
    }
}
