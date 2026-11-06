pragma ComponentBehavior: Bound

import QtQuick
import "../../services"
import "./zones"

// Notch zones, each independently anchored to where it actually belongs on
// screen — NOT a single Row, because the zones have fundamentally different
// anchor semantics: TL is flush against the real top-left screen corner
// (needed for its square/round CornerPill silhouette), while N-C must sit
// at the screen's true horizontal center regardless of TL's width. Packing
// them into one left-flush Row (the original Phase 1/2 approach) made "N-C"
// actually mean "immediately right of TL," which visibly wasn't centered —
// fixed by anchoring each zone to this Item, which itself now spans the
// full window width (see Notch.qml), independently.
//
// Future zones: intermediate-left sits between TL and N-C (anchor its own
// left to TL's right, or right to N-C's left); intermediate-right/TR mirror
// that on N-C's other side, with TR ultimately flush against the real
// top-right screen corner (anchors.right: parent.right), matching TL's
// flush-left treatment. BR is a separate standalone corner zone, not part
// of this top-row Item at all — see sdd/notch-redesign design.
Item {
    id: root

    required property string screenName
    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    readonly property var colors: Colours.paletteFor(root.screenName)

    implicitHeight: Math.max(tl.implicitHeight, nc.implicitHeight)

    TLZone {
        id: tl
        anchors.left: parent.left
        anchors.top:  parent.top
        colors:       root.colors
    }

    // TODO Phase 5: intermediate-left zone (between TL and N-C)

    // N-C zone (Phase 2): idle clock + CPU/RAM glance meters, swapped for
    // an equalizer glyph while music plays. Hover-expand-to-media content
    // is still Phase 3+ scope — see NCZone.qml. Anchored to this Item's
    // TRUE horizontal center (see class comment above for why this isn't a
    // Row position).
    NCZone {
        id: nc
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:              parent.top
        colors:                   root.colors
    }

    // TODO Phase 5: intermediate-right zone (between N-C and TR)

    // TODO Phase 6/7: TR zone (flush top-right screen corner)

    // TODO Phase 8: BR zone (separate standalone corner zone, not part of
    // this top-row Item)
}
