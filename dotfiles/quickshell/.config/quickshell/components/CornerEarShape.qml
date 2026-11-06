pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "EarCurve.js" as EarCurve

// Asymmetric "corner ear" silhouette for screen-CORNER-anchored notch zones
// (TL now; TR/BL/BR reuse this once their own phases land — see
// sdd/notch-redesign design's corner-zone shape rule). Sibling of
// components/NotchEarShape.qml, which stays reserved for the true
// center-anchored N-C zone (both top corners concave, both bottom corners
// convex, symmetric) — do NOT merge the two. A corner zone sits with ONE
// real screen corner (both of its OWN two edges there are physically flush
// against real screen borders) and needs 4 DIFFERENT corner treatments
// derived from a single `anchorCorner`:
//
//   - the anchor corner itself (where the panel's two flush edges meet) =
//     SQUARE (radius 0) — it sits exactly in the real screen corner, no
//     ear, no round, no gap.
//   - the two corners ADJACENT to the anchor (the far end of each flush
//     edge, moving away from the anchor toward the panel's own free side)
//     = CONCAVE "ear" transitions — same technique as NotchEarShape.
//   - the corner OPPOSITE the anchor (touching NEITHER flush edge) =
//     normal CONVEX rounded corner.
//
// SQUARE and ROUND corners keep the original PathArc technique (a convex
// fillet has no tangent-continuity problem — see components/EarCurve.js
// for why the concave "ear" case is different). A "square" corner is just
// that same arc forced to radius 0 (degenerates to a point, same clamp
// trick NotchEarShape already uses while its height animates from ~0).
//
// EAR corners use the shared tangent-continuous compound curve from
// components/EarCurve.js (same technique/module as NotchEarShape.qml) —
// NOT PathArc — for exactly the same reason NotchEarShape switched: an arc
// centered at the true corner has a 90-degree tangent mismatch at both
// endpoints.
//
// LIMITATION (current phase): QtQuick.Shapes path elements are statically
// typed per slot, so a given corner slot in the path below can't switch
// between PathArc and PathCubic at runtime. `anchorCorner` is only ever
// set to "topLeft" today (TLZone.qml — the only live caller), which always
// puts the ear pair at TR/BL and square/round at TL/BR, so those 4 slots
// are hardcoded to that layout: TL/BR stay PathArc, TR/BL are PathCubic.
// A future phase wiring up a different `anchorCorner` (TR/BL/BR) needs to
// generalize this (e.g. a PathSvg-built path chosen per-corner-type at
// runtime) instead of assuming TR/BL are always the ear slots.
Item {
    id: root

    property color fillColor:   "black"
    property color borderColor: "transparent"
    property real  borderWidth: 0
    property real  earRadius:    10
    property real  cornerRadius: 8

    // Which real screen corner this zone is flush against — decides which
    // of the 4 corners below is square/ear/ear/round. Mirrored for the
    // other 3 corners once their zones land (TR, BL, BR).
    property string anchorCorner: "topLeft" // "topLeft" | "topRight" | "bottomLeft" | "bottomRight"

    // Clamped so the path stays well-formed while implicitHeight animates
    // from ~0 up (NotchDropdown's vertical reveal) — same reasoning as
    // NotchEarShape's _er/_cr.
    readonly property real _er: Math.max(0, Math.min(root.earRadius,    root.width / 2, root.height))
    readonly property real _cr: Math.max(0, Math.min(root.cornerRadius, root.width / 2, root.height))

    function _isAdjacent(corner) {
        switch (root.anchorCorner) {
        case "topLeft":     return corner === "topRight" || corner === "bottomLeft"
        case "topRight":    return corner === "topLeft"  || corner === "bottomRight"
        case "bottomLeft":  return corner === "topLeft"  || corner === "bottomRight"
        case "bottomRight": return corner === "topRight" || corner === "bottomLeft"
        default:            return false
        }
    }

    function _cornerType(corner) {
        if (corner === root.anchorCorner) return "square"
        if (root._isAdjacent(corner))     return "ear"
        return "round"
    }

    function _radiusFor(type) {
        if (type === "ear")   return root._er
        if (type === "round") return root._cr
        return 0 // square
    }

    function _directionFor(type) {
        return type === "ear" ? PathArc.Counterclockwise : PathArc.Clockwise
    }

    readonly property string _tlType: root._cornerType("topLeft")
    readonly property string _trType: root._cornerType("topRight")
    readonly property string _brType: root._cornerType("bottomRight")
    readonly property string _blType: root._cornerType("bottomLeft")

    readonly property real _tlR: root._radiusFor(root._tlType)
    readonly property real _trR: root._radiusFor(root._trType)
    readonly property real _brR: root._radiusFor(root._brType)
    readonly property real _blR: root._radiusFor(root._blType)

    // Extra "reach" (k, clamped per available edge length) and
    // control-point tangent length (d) for the two ear corners — see
    // components/EarCurve.js. Tuned visually against the
    // "flat-then-smoothly-curving" reference (see sdd/notch-redesign
    // apply-progress for the iteration notes).
    readonly property real _earKTr: Math.max(0, Math.min(root._trR * 0.6, root.height - root._trR - root._brR))
    readonly property real _earKBl: Math.max(0, Math.min(root._blR * 0.6, root.width  - root._blR - root._brR))
    readonly property real _earD:   root._er * 1.3

    // Top-right ear: entering edge = top, leaving edge = right. Extend
    // whichever endpoint borders the ROUND neighbor corner (see
    // EarCurve.js's earCubic doc) — top-left's own type decides the
    // entering side, bottom-right's decides the leaving side.
    readonly property var _trCurve: EarCurve.earCubic(
        root.width, 0, root._trR, root._earKTr, root._earD,
        Qt.point(1, 0), Qt.point(0, 1), root._tlType === "round")

    // Bottom-left ear: entering edge = bottom, leaving edge = left.
    readonly property var _blCurve: EarCurve.earCubic(
        0, root.height, root._blR, root._earKBl, root._earD,
        Qt.point(-1, 0), Qt.point(0, -1), root._brType === "round")

    Shape {
        id: shape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor:   root.fillColor
            strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
            strokeWidth: root.borderWidth > 0 ? root.borderWidth : -1

            startX: root._tlR
            startY: 0

            // Top edge, between the top-left and top-right corners.
            PathLine { x: root._trCurve.startX; y: root._trCurve.startY }

            // Top-right corner — tangent-continuous ear compound curve.
            // (Only valid while anchorCorner === "topLeft", see the
            // LIMITATION note above the Item block.)
            PathCubic {
                x: root._trCurve.endX
                y: root._trCurve.endY
                control1X: root._trCurve.c1x
                control1Y: root._trCurve.c1y
                control2X: root._trCurve.c2x
                control2Y: root._trCurve.c2y
            }

            // Right edge.
            PathLine { x: root.width; y: root.height - root._brR }

            // Bottom-right corner.
            PathArc {
                x: root.width - root._brR
                y: root.height
                radiusX: root._brR
                radiusY: root._brR
                direction: root._directionFor(root._brType)
            }

            // Bottom edge.
            PathLine { x: root._blCurve.startX; y: root._blCurve.startY }

            // Bottom-left corner — tangent-continuous ear compound curve.
            // (Only valid while anchorCorner === "topLeft", see the
            // LIMITATION note above the Item block.)
            PathCubic {
                x: root._blCurve.endX
                y: root._blCurve.endY
                control1X: root._blCurve.c1x
                control1Y: root._blCurve.c1y
                control2X: root._blCurve.c2x
                control2Y: root._blCurve.c2y
            }

            // Left edge.
            PathLine { x: 0; y: root._tlR }

            // Top-left corner, closes back to startX/startY.
            PathArc {
                x: root._tlR
                y: 0
                radiusX: root._tlR
                radiusY: root._tlR
                direction: root._directionFor(root._tlType)
            }
        }
    }
}
