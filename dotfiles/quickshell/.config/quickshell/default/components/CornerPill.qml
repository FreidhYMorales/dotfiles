pragma ComponentBehavior: Bound

import QtQuick

// Simplified background for screen-CORNER-anchored notch zones (TL now;
// TR/BL/BR reuse this once their own phases land — see sdd/notch-redesign
// design's corner-zone shape rule). Fill color only, no border, no ear
// curves — a plain `Rectangle` using Qt 6.7+'s native per-corner radius
// properties (`topLeftRadius`/`topRightRadius`/`bottomLeftRadius`/
// `bottomRightRadius`), which animate smoothly via a plain `Behavior` and
// don't recompute a path every frame like a `Shape` does.
//
// Replaces the concave "ear" silhouette (components/CornerEarShape.qml)
// for now — the ear curves were dropped as a simplification pass after 3
// rounds of trying to get the concave shape right (see sdd/notch-redesign
// apply-progress). CornerEarShape/NotchEarShape/EarCurve.js stay on disk,
// unused, for a possible future revisit.
//
// Simplified corner rule (explicit, literal): every corner that lies ON a
// flush screen edge is SQUARE; the one corner touching NEITHER flush edge
// is ROUND. A corner-anchored panel always has exactly one free corner —
// it's the corner diagonally OPPOSITE the anchor corner. For a
// top-left-anchored panel (flush top + flush left, anchored at the real
// top-left screen corner): top-left, top-right, and bottom-left are all
// square; bottom-right (the only corner touching neither flush edge) is
// round.
Rectangle {
    id: root

    // Which real screen corner this zone is flush against — decides which
    // of the 4 corners is round (the diagonally opposite one). Mirrored
    // for the other 3 corners once their zones land (TR, BL, BR).
    property string anchorCorner: "topLeft" // "topLeft" | "topRight" | "bottomLeft" | "bottomRight"
    property real   roundRadius:  8

    readonly property string _roundCorner: {
        switch (root.anchorCorner) {
        case "topLeft":     return "bottomRight"
        case "topRight":    return "bottomLeft"
        case "bottomLeft":  return "topRight"
        case "bottomRight": return "topLeft"
        default:            return "bottomRight"
        }
    }

    radius: 0
    topLeftRadius:     root._roundCorner === "topLeft"     ? root.roundRadius : 0
    topRightRadius:    root._roundCorner === "topRight"    ? root.roundRadius : 0
    bottomLeftRadius:  root._roundCorner === "bottomLeft"  ? root.roundRadius : 0
    bottomRightRadius: root._roundCorner === "bottomRight" ? root.roundRadius : 0

    // Fill color only — no colored border. Explicit width: 0 rather than
    // relying on Rectangle's default (transparent color, width 1) so it
    // reads clearly on inspection that no border is intended at all.
    border.width: 0
}
