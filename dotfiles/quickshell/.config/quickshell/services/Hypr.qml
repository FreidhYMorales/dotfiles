pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland state service — thin live bindings onto Quickshell's own
// Hyprland module (toplevels/workspaces/monitors), free/event-driven.
//
// Used to also poll caps/num lock and keyboard layout via a 3s Timer
// forking `bash -c "hyprctl devices -j | python3 -c ..."` — a fresh Python
// interpreter every 3s, forever. Removed: grep confirmed nothing in the
// project (outside the unrelated lock/ virtual-keyboard bundle) ever read
// capsLock/numLock/kbLayout*/activeClass/activeTitle — dead Caelestia-
// compat stub, never wired to a widget. If this state is needed later,
// wire it from Hyprland.rawEvent (activelayout event) instead of polling.
Singleton {
    id: root

    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel
    readonly property var toplevels:   Hyprland.toplevels
    readonly property var workspaces:  Hyprland.workspaces
    readonly property var monitors:    Hyprland.monitors
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property HyprlandMonitor   focusedMonitor:   Hyprland.focusedMonitor

    function dispatch(request) {
        Hyprland.dispatch(request)
    }
}
