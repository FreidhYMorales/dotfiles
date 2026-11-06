pragma ComponentBehavior: Bound

import QtQuick
import "../services"

// Generalized VERTICAL-reveal hover-hitbox base for the notch redesign's
// top-row zones (TL now; intermediate-left/right and TR reuse this same
// base once their own phases land). Sibling of components/NotchZone.qml,
// which stays the correct base for N-C's horizontal pill-expand — do not
// merge the two, they're deliberately different contracts for different
// interaction models (this rework's corrected design: N-C still expands
// horizontally later, TL/TR/intermediate zones expand vertically now).
//
// Collapsed state is a near-invisible `hitboxHeight`-tall strip spanning
// the zone's full content width (so hover is detectable at all — Wayland
// has no true zero-size-but-hoverable surface) with the caller's content
// fully hidden (opacity 0), not just clipped — a clip-only strip would
// still show a sliver of whatever's drawn at y=0..hitboxHeight. On
// hover (or `externalExpanded`), `implicitHeight` grows downward from
// that strip to the content's needed height (or `expandedHeight` if set).
//
// Purely structural — no fill/border/radius of its own. Callers put their
// visual chrome (NotchEarShape, etc.) as a sibling bound to this item's
// live (animated) size, same convention TLZone.qml already used around
// NotchZone.
Item {
    id: root

    default property alias data: content.data
    readonly property alias content: content

    property int  hitboxHeight:     4         // invisible strip height when collapsed
    property int  expandedHeight:   0         // 0 = size to content.implicitHeight
    property bool externalExpanded: false     // set by caller to force-expand (e.g. R12 empty-workspace)
    property bool expanded:         hov.hovered || root.externalExpanded
    property int  closeDelayMs:     0         // >0 adds a Timer before collapsing

    readonly property alias hovered:  hov.hovered
    // Public read-only mirror of the (debounced) expanded state — callers
    // need this to hide sibling background chrome (e.g. NotchEarShape) at
    // idle too, not just this base's own `content`.
    readonly property alias revealed: root._effectiveExpanded

    signal clicked()

    // `expanded` flips back to false immediately on hover-out/external
    // change; closeDelayMs (when >0) holds the expanded size for that long
    // before actually collapsing, instead of collapsing on the same tick.
    property bool _effectiveExpanded: expanded

    onExpandedChanged: {
        if (expanded) {
            closeTimer.stop()
            root._effectiveExpanded = true
        } else if (closeDelayMs > 0) {
            closeTimer.restart()
        } else {
            root._effectiveExpanded = false
        }
    }

    implicitWidth:  content.implicitWidth
    implicitHeight: root._effectiveExpanded
        ? (expandedHeight > 0 ? expandedHeight : content.implicitHeight)
        : hitboxHeight
    clip: true

    Behavior on implicitHeight { Anim { type: Anim.Enter } }

    Timer {
        id: closeTimer
        interval: root.closeDelayMs
        onTriggered: root._effectiveExpanded = false
    }

    Item {
        id: content
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth:  childrenRect.width
        implicitHeight: childrenRect.height

        // Zero visual presence at idle (requirement: hide COMPLETELY by
        // default) — clip alone would still show a hitboxHeight-tall
        // sliver of whatever's drawn at the top of the content.
        //
        // Uses the SAME Anim.Enter duration/easing as implicitHeight's own
        // Behavior below, not an independent NumberAnimation. This used to
        // be a plain `NumberAnimation { duration: 120 }` (linear, 120ms)
        // racing against implicitHeight's 200ms OutCubic — opacity always
        // reached 1 well before the height finished expanding (and reached
        // 0 well before height finished collapsing), so content snapped
        // fully visible/invisible mid-reveal while the box kept growing/
        // shrinking underneath it. That duration/easing mismatch is a
        // classic cause of a "flickery"/"not smooth" expand-collapse —
        // keeping both Behaviors on the same Anim type keeps them in
        // lockstep instead.
        opacity: root._effectiveExpanded ? 1 : 0
        Behavior on opacity { Anim { type: Anim.Enter } }
    }

    HoverHandler { id: hov }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false // hover/expand handled by HoverHandler above
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
