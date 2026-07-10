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

            visible: notifContent.open &&
                     screenScope.modelData.name === (Hyprland.focusedMonitor?.name ?? "")

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "deadlock-notifications"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors { top: true; right: true }
            margins { top: 43; right: 8 }
            implicitWidth:  324
            implicitHeight: 300

            MouseArea {
                anchors.fill: parent
                z:            0
                enabled:      Visibilities.notifications
                onClicked:    Visibilities.toggle("notifications")
            }

            NotificationPanelContent {
                id:           notifContent
                anchors.fill: parent
                z:            1
            }
        }
    }
}
