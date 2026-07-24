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

            // 10px, not 8 — must be a multiple of 5 so margin * scale (1.2
            // on this monitor) lands on a whole physical pixel. At 8px the
            // left/right border edges rounded to different pixel widths.
            margins {
                top:   10
                left:  10
                right: 10
            }

            implicitHeight: 36

            BarContent {
                anchors.fill: parent
                screenName:   screenScope.modelData.name
            }
        }
    }
}
