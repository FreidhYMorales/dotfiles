pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"

// One WlrLayershell surface per monitor at the Wayland "background" layer.
// hyprpaper is left running as a passive fallback (see lockscreen.md /
// project docs) — its static wallpaper only ever becomes visible if this
// surface disappears (e.g. Quickshell crashes), since this one renders on
// top while the shell is alive.
Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: screenScope
        required property ShellScreen modelData

        PanelWindow {
            id: bgWindow
            screen: screenScope.modelData
            color:  "black"

            WlrLayershell.layer:         WlrLayer.Background
            WlrLayershell.namespace:     "deadlock-wallpaper"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors { top: true; bottom: true; left: true; right: true }

            BackgroundSurface {
                anchors.fill: parent
                screenName:   screenScope.modelData.name
            }

            // Caffeine mode — pauses the screensaver/lock/suspend chain via
            // IdleMonitor.respectInhibitors (services/IdleManager.qml). Lives
            // here rather than in the screensaver module because
            // IdleInhibitor.window needs an ALWAYS-mapped surface — the
            // screensaver's own PanelWindow is only visible once idle is
            // already true, so an inhibitor attached there flickers the
            // screensaver on for ~150ms every cycle before it can take
            // effect (confirmed empirically). This background window is
            // always mapped, so the inhibitor is live from the start.
            IdleInhibitor {
                enabled: IdleManager.caffeineMode
                window:  bgWindow
            }
        }
    }
}
