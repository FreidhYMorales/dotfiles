pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick

Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: screenScope
        required property ShellScreen modelData

        PanelWindow {
            screen: screenScope.modelData
            color:  "transparent"

            WlrLayershell.layer:          WlrLayer.Top
            WlrLayershell.namespace:      "deadlock-bar"
            WlrLayershell.exclusiveZone:  44

            anchors {
                top:   true
                left:  true
                right: true
            }

            margins {
                top:   8
                left:  8
                right: 8
            }

            implicitHeight: 36

            BarContent {
                anchors.fill: parent
                screenName:   screenScope.modelData.name
            }
        }
    }
}
