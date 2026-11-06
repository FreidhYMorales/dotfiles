pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"

// Notch host — top-center overlay surface, replicated on every monitor
// (no isFocused gate; mirrors modules/powermenu/PowerMenuOsd.qml's
// per-monitor Variants -> Scope -> PanelWindow structure and
// modules/background/Background.qml's same pattern). Runs alongside the
// existing Bar {} during the notch redesign's parallel-rollout phase —
// shell.qml instantiates both, nothing removed.
//
// WlrLayershell.exclusiveZone is hardcoded to -1 (overlay/floating, no
// reserved screen space) for Phase 1 — Phase 9 wires this to the already
//-persisted NotchConfig.reserveSpace toggle. Do not bind it here yet.
Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: screenScope
        required property ShellScreen modelData

        PanelWindow {
            id: win
            screen: screenScope.modelData
            color:  "transparent"

            WlrLayershell.layer:         WlrLayer.Top
            WlrLayershell.namespace:     "deadlock-notch"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Full-width, flush top+left+right (no margins) — like the old
            // Bar.qml pattern. A single top-only anchor centers the WHOLE
            // SURFACE horizontally (standard wlr-layer-shell behavior for
            // one anchored edge) — that was the actual bug: TL's content
            // already started at local (0,0), but the window itself sat at
            // screen horizontal-center, not real screen x=0. Anchoring
            // left+right too pins the window's own top-left corner to
            // literal screen (0,0), which TLZone's square corner needs.
            // Full width also leaves room for future zones (N-C centered,
            // TR flush right) without another window-level restructure.
            anchors {
                top:   true
                left:  true
                right: true
            }

            // FIXED window height, not bound to the animating content height.
            // The earlier `implicitHeight: content.implicitHeight` bound the
            // actual Wayland surface size to TLZone's animating expand/
            // collapse height — resizing the real wlr-layer-shell surface on
            // every animation frame (a compositor-level reconfigure, not
            // just a QML property change) is what caused the reported
            // flicker, confirmed by ruling out the state machine itself via
            // live debug logging (expanded/hovered transitions were clean,
            // no bouncing). Every other OSD in this project (see
            // components/MonitorOsdWindow.qml's `implicitHeight:
            // root.osdHeight`) already uses a fixed window size with
            // internal animation — this matches that established pattern.
            // TL's content height is 42px (26px icon + 8px top/bottom
            // padding); N-C's is 50px (30px content row + 10px top/bottom
            // padding) — dialed back from an over-scaled 78px pass that
            // only became visible/judgeable once NotchZone.qml's clip-
            // height bug (see that file's own comment) was fixed. 60px
            // keeps headroom over N-C's current max; revisit when TR lands.
            implicitHeight: 60

            // Spans the FULL window width (left+right, not just left) so
            // NotchContent's own zones can anchor to true screen-center
            // (horizontalCenter) or the true right edge independently of
            // TL's flush-left position — a left-only anchor here would make
            // "screen center" actually mean "center of whatever width TL's
            // content happens to be," which is wrong once more than one
            // real zone exists (confirmed live: N-C rendered squeezed next
            // to TL instead of centered, before this fix).
            NotchContent {
                id: content
                anchors.left:  parent.left
                anchors.right: parent.right
                anchors.top:   parent.top
                screenName:    screenScope.modelData.name
            }
        }
    }
}
