pragma ComponentBehavior: Bound

import QtQuick
import "../services"

// Generalized hover-hitbox base for the notch redesign (modules/notch/*,
// Phase 1+). Lifts BgAppsWidget.qml's proven hover-expand pattern
// (`implicitWidth: (hov.hovered || ...) ? innerRow.implicitWidth + 16 : 26`
// driving a `Behavior on implicitWidth`) into a reusable, content-agnostic
// shape so every notch zone doesn't reimplement it.
//
// Purely structural — no fill/border/radius of its own. Callers put their
// visual chrome (Rectangle, StateLayer, etc.) as children; those land in
// the internal `content` Item via the default `data` alias and get sized
// through `content.implicitWidth`/`implicitHeight` (childrenRect-based, so
// a plain Row/Item child works without extra wiring, same as BgAppsWidget's
// innerRow).
Item {
    id: root

    default property alias data: content.data
    readonly property alias content: content

    property int  idleWidth:        26
    property int  expandedWidth:    0        // 0 = size to content.implicitWidth
    property bool hoverToExpand:    true      // false for NCZone (external triggers drive it)
    property bool externalExpanded: false     // set by caller when hoverToExpand=false
    property bool expanded:         hoverToExpand ? hov.hovered : externalExpanded
    property int  closeDelayMs:     0         // >0 adds a Timer before collapsing

    readonly property alias hovered: hov.hovered

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

    implicitWidth: root._effectiveExpanded
        ? (expandedWidth > 0 ? expandedWidth : content.implicitWidth)
        : idleWidth
    // Height always matches content — unlike width, this base's
    // idle/expanded distinction is purely horizontal (N-C never collapses
    // vertically, it's the one zone that stays permanently visible). Was
    // hardcoded to 26 (this component's original spec, sized for N-C's
    // first, much smaller content) — with `clip: true` below, that silently
    // clipped away every later height increase (bigger clock font, bigger
    // ArcMeter rings, extra padding) to a fixed 26px window, which is why
    // "make the notch taller" appeared to do nothing no matter how much
    // padding/content size was added — confirmed live, this was the actual
    // bug, not insufficient padding.
    implicitHeight: content.implicitHeight
    clip: true

    Behavior on implicitWidth { Anim { type: Anim.Enter } }

    Timer {
        id: closeTimer
        interval: root.closeDelayMs
        onTriggered: root._effectiveExpanded = false
    }

    Item {
        id: content
        anchors.centerIn: parent
        implicitWidth:  childrenRect.width
        implicitHeight: childrenRect.height
    }

    HoverHandler { id: hov }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false // hover/expand handled by HoverHandler above
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
