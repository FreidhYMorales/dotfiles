.pragma library

// Shared tangent-continuous "ear" curve construction, used by both
// NotchEarShape.qml and CornerEarShape.qml so their concave-corner math
// can't drift apart again.
//
// THE BUG THIS REPLACES: a single PathArc for a concave "ear", centered at
// the true rectangle corner, has a 90-degree tangent mismatch at BOTH of
// its endpoints against the straight edges it's supposed to blend into —
// that's what reads as a diagonal/chamfered "cut" instead of a flowing
// ear. A normal CONVEX fillet doesn't have this problem (its arc is
// centered at the INSET point, not the true corner), which is why plain
// rounded corners already look smooth.
//
// THE FIX: a cubic Bezier between the two edge-endpoints, with each
// control point placed along its own endpoint's edge tangent direction
// (`enteringDir`/`leavingDir`). That pins the curve's tangent at each
// endpoint to match the straight edge it meets — no kink — independent of
// the curve's concave/convex sign. `d` is how far each control point
// travels along that tangent before the curve bends (bigger d = more
// "flowing", smaller d = tighter).
//
// An "ear" also needs to read as MORE than a plain fillet, so one of its
// two endpoints is pushed an extra `k` further from the corner (along
// whichever adjacent edge borders a genuinely convex round corner — see
// CornerEarShape.qml's per-corner neighbor check) while the other endpoint
// stays at the plain radius distance `r`. Which endpoint gets the `k`
// extension is the caller-supplied `extendEntering` flag.
//
// `enteringDir`/`leavingDir` are unit vectors (axis-aligned, e.g.
// {x:1,y:0}) for the direction of travel of the edge entering / leaving
// this corner, in the shape's overall clockwise path order.
function earCubic(cornerX, cornerY, r, k, d, enteringDir, leavingDir, extendEntering) {
    var startX = cornerX - enteringDir.x * r
    var startY = cornerY - enteringDir.y * r
    var endX   = cornerX + leavingDir.x * r
    var endY   = cornerY + leavingDir.y * r

    if (extendEntering) {
        startX = cornerX - enteringDir.x * (r + k)
        startY = cornerY - enteringDir.y * (r + k)
    } else {
        endX = cornerX + leavingDir.x * (r + k)
        endY = cornerY + leavingDir.y * (r + k)
    }

    return {
        startX: startX, startY: startY,
        endX:   endX,   endY:   endY,
        c1x: startX + enteringDir.x * d,
        c1y: startY + enteringDir.y * d,
        c2x: endX   - leavingDir.x * d,
        c2y: endY   - leavingDir.y * d
    }
}
