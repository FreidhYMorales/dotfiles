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

            // Stay visible during close animation (launcherContent.stage drives actual opacity)
            visible: (launcherContent.stage !== "closed" || Visibilities.launcher) &&
                     screenScope.modelData.name === (Hyprland.focusedMonitor?.name ?? "")

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "deadlock-launcher"
            WlrLayershell.exclusiveZone: -1
            // Release keyboard immediately on close; content fades out independently
            WlrLayershell.keyboardFocus: Visibilities.launcher ? WlrKeyboardFocus.Exclusive
                                                               : WlrKeyboardFocus.None

            anchors { bottom: true; left: true; right: true }
            margins { bottom: 8 }

            implicitHeight: 560

            // Dismiss on click outside the panel (only active while launcher is "open")
            MouseArea {
                anchors.fill: parent
                z:            0
                enabled:      Visibilities.launcher
                onClicked:    Visibilities.toggle("launcher")
            }

            LauncherContent {
                id:      launcherContent
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                width:   600
                height:  parent.height
                z:       1
            }
        }
    }
}
