pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../../services"
import "../../../components"
import "../../bar"

// TL zone — launcher trigger + workspace list. The special-workspace
// indicator is FUSED into this same panel (explicit design correction from
// the design phase: not a separate NotchZone-wrapped component).
// LauncherButton/WorkspacesWidget/SpecialWorkspacesWidget already exist as
// independent bar widgets and are reused as-is here, just grouped inside
// one NotchDropdown hover-hitbox instead of living in the bar's own pill.
//
// MAJOR design correction (see sdd/notch-redesign design, "vertical reveal
// + corner-pill silhouette"): this used to be a horizontal pill-expand
// (NotchZone) with the launcher icon always visible at idle. It's now a
// vertical dropdown (NotchDropdown) hidden completely at idle, revealing
// downward with a simplified square/round corner silhouette (CornerPill)
// on hover or while the focused workspace is empty. (An earlier pass tried
// a concave-top "ear" silhouette — NotchEarShape/CornerEarShape — but that
// was dropped as a simplification; see CornerPill.qml.)
Item {
    id: root

    // Per-monitor palette (bar/panels only — see Colours.paletteFor),
    // forwarded down from NotchContent.
    property var colors: Colours.palette

    implicitWidth:  dropdown.implicitWidth
    implicitHeight: dropdown.implicitHeight

    // R12 — persistent visibility: this zone stays expanded without hover
    // while the focused workspace has zero toplevels, and falls back to
    // hover-driven expand/collapse once a window opens.
    // `.toplevels.values.length`, NOT `.count` — Quickshell's ObjectModel
    // has no "count" property (only "values"), ".count" silently coerces
    // to 0 on this build (same gotcha SpecialWorkspacesWidget.qml already
    // documents).
    //
    // NOTE for Phase 2+: this Hyprland query is computed locally here
    // rather than shared. If later zones need the same "stay visible while
    // empty" behavior, lift it into NotchContent.qml or a small shared
    // helper instead of duplicating the query per zone.
    readonly property bool focusedWorkspaceEmpty:
        (Hyprland.focusedMonitor?.activeWorkspace?.toplevels?.values?.length ?? 0) === 0

    // Corner-pill chrome — NotchDropdown is purely structural (no fill/
    // border of its own), so this lives as a sibling bound to dropdown's
    // live (animated) size instead of as a child of NotchDropdown's
    // `content` (which would create a childrenRect sizing loop). Same
    // "chrome as a sibling" convention TLZone previously used around
    // NotchZone. CornerPill (simplification pass — replaces CornerEarShape
    // here; the concave "ear" curves were dropped for now, see
    // sdd/notch-redesign apply-progress; CornerEarShape/NotchEarShape/
    // EarCurve.js stay on disk unused for a possible future revisit): TL is
    // a screen-CORNER zone, flush against the real top-left screen corner
    // (see Notch.qml's full-width top+left+right anchoring), so 3 of its 4
    // corners (the ones on a flush edge) are square and only the free
    // bottom-right corner is round. Fill color only — no colored border.
    CornerPill {
        anchors.fill: dropdown
        color:        root.colors.m3surfaceContainerHigh
        roundRadius:  Style.cornerRadius
        anchorCorner: "topLeft"

        // Idle state must have ZERO visual presence — NotchDropdown only
        // hides its own `content`; this chrome is a sibling bound to
        // `dropdown`'s live size, so it needs the same idle-hide wired in
        // separately or it'd render as a hitboxHeight-tall sliver. Uses the
        // same Anim.Enter duration/easing as NotchDropdown's own
        // implicitHeight Behavior (see components/NotchDropdown.qml) so
        // this chrome's fade-in/out stays in lockstep with the height
        // reveal instead of finishing early/late and reading as a flicker.
        opacity: dropdown.revealed ? 1 : 0
        Behavior on opacity { Anim { type: Anim.Enter } }
    }

    NotchDropdown {
        id: dropdown

        hitboxHeight:     4
        externalExpanded: root.focusedWorkspaceEmpty
        closeDelayMs:     300

        Row {
            id: tlRow
            spacing: 6
            topPadding: 8
            leftPadding: 8
            rightPadding: 8
            bottomPadding: 8

            LauncherButton { standalone: false; colors: root.colors }

            Row {
                spacing: 5
                WorkspacesWidget        { colors: root.colors }
                SpecialWorkspacesWidget { colors: root.colors }
            }
        }
    }
}
