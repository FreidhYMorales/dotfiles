pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../../services"

Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: screenScope
        required property ShellScreen modelData

        PanelWindow {
            screen: screenScope.modelData
            color:  "transparent"

            // Visible while animating or open, only on the focused monitor
            visible: dashContent.open &&
                     screenScope.modelData.name === (Hyprland.focusedMonitor?.name ?? "")

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "deadlock-dashboard"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors { top: true; right: true; bottom: true }
            margins { top: 43; right: 8; bottom: 8 }
            implicitWidth: 340

            // Dismiss on click outside the panel content
            MouseArea {
                anchors.fill: parent
                z:            0
                enabled:      Visibilities.dashboard
                onClicked:    Visibilities.toggle("dashboard")
            }

            DashboardContent {
                id:          dashContent
                anchors.fill: parent
                z:            1
            }
        }
    }
}
