pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "EarCurve.js" as EarCurve

// "Dynamic Island / camera notch" silhouette — the two TOP corners are
// CONCAVE "ear" cutouts and the two BOTTOM corners are normal CONVEX
// rounded corners.
//
// The two ears are built as tangent-continuous compound curves (see
// components/EarCurve.js for the full diagnosis/technique), NOT a single
// PathArc centered at the true corner — that earlier approach had a
// 90-degree tangent mismatch at both ends of the arc, which is what made
// it read as a diagonal "cut" instead of a flowing ear.
//
// Explicit QtQuick.Shapes path (PathLine + PathArc/PathCubic) instead of
// QtQuick.Effects.MultiEffect masking — this project already hit
// reliability problems with mask-based rounded-corner approaches (oval
// artifacts, bounds misalignment, a flicker regression) earlier in the
// notch-redesign work, so this draws the outline directly.
//
// Used as a sibling background behind a NotchDropdown's live (animated)
// size — same "chrome lives outside the structural base" convention
// components/NotchZone.qml already established for its callers.
Item {
    id: root

    property color fillColor:   "black"
    property color borderColor: "transparent"
    property real  borderWidth: 0
    property real  earRadius:    10
    property real  cornerRadius: 8

    // Clamped so the path stays well-formed while implicitHeight animates
    // from ~0 up (NotchDropdown's vertical reveal) — an unclamped radius
    // larger than half the current height/width produces a degenerate/
    // self-intersecting path for a couple of animation frames.
    readonly property real _er: Math.max(0, Math.min(root.earRadius,    root.width / 2, root.height))
    readonly property real _cr: Math.max(0, Math.min(root.cornerRadius, root.width / 2, root.height))

    // Extra "reach" (k) and control-point tangent length (d) for the ear
    // curves, both derived from _er and clamped to the currently available
    // height so the extended endpoint never overshoots past the opposite
    // (bottom) corner's own radius while implicitHeight animates from ~0.
    // Tuned visually against the "flat-then-smoothly-curving" reference
    // (see sdd/notch-redesign apply-progress for the iteration notes).
    readonly property real _earK: Math.max(0, Math.min(root._er * 0.6, root.height - root._er - root._cr))
    readonly property real _earD: root._er * 1.3

    // Top-right ear: entering edge = top (going +x), leaving edge = right
    // (going +y). The right edge borders the (round) bottom-right corner,
    // so the extended endpoint is the leaving one (further down the right
    // edge) — see EarCurve.js.
    readonly property var _trCurve: EarCurve.earCubic(
        root.width, 0, root._er, root._earK, root._earD,
        Qt.point(1, 0), Qt.point(0, 1), false)

    // Top-left ear: entering edge = left (going -y), leaving edge = top
    // (going +x). The left edge borders the (round) bottom-left corner, so
    // the extended endpoint is the entering one (further down the left
    // edge).
    readonly property var _tlCurve: EarCurve.earCubic(
        0, 0, root._er, root._earK, root._earD,
        Qt.point(0, -1), Qt.point(1, 0), true)

    Shape {
        id: shape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor:   root.fillColor
            strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
            strokeWidth: root.borderWidth > 0 ? root.borderWidth : -1

            startX: root._tlCurve.endX
            startY: root._tlCurve.endY

            // Flat top edge, between the two ears.
            PathLine { x: root._trCurve.startX; y: root._trCurve.startY }

            // Top-right concave ear — tangent-continuous compound curve
            // (see components/EarCurve.js), not a single PathArc centered
            // at the true corner.
            PathCubic {
                x: root._trCurve.endX
                y: root._trCurve.endY
                control1X: root._trCurve.c1x
                control1Y: root._trCurve.c1y
                control2X: root._trCurve.c2x
                control2Y: root._trCurve.c2y
            }

            // Right edge.
            PathLine { x: root.width; y: root.height - root._cr }

            // Bottom-right convex corner — standard fillet.
            PathArc {
                x: root.width - root._cr
                y: root.height
                radiusX: root._cr
                radiusY: root._cr
                direction: PathArc.Clockwise
            }

            // Bottom edge.
            PathLine { x: root._cr; y: root.height }

            // Bottom-left convex corner — standard fillet.
            PathArc {
                x: 0
                y: root.height - root._cr
                radiusX: root._cr
                radiusY: root._cr
                direction: PathArc.Clockwise
            }

            // Left edge.
            PathLine { x: 0; y: root._tlCurve.startY }

            // Top-left concave ear — tangent-continuous compound curve,
            // closes the path back to startX/startY.
            PathCubic {
                x: root._tlCurve.endX
                y: root._tlCurve.endY
                control1X: root._tlCurve.c1x
                control1Y: root._tlCurve.c1y
                control2X: root._tlCurve.c2x
                control2Y: root._tlCurve.c2y
            }
        }
    }
}
