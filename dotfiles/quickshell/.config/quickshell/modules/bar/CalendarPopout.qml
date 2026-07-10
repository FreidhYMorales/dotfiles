pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import "../../services"
import "../../components"

Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: screenScope
        required property ShellScreen modelData

        PanelWindow {
            id: win
            screen: screenScope.modelData
            color:  "transparent"

            readonly property bool isFocused:
                screenScope.modelData.name === (Hyprland.focusedMonitor?.name ?? "")

            property bool _calVisible: false

            visible: isFocused && win._calVisible

            Timer { id: calHideTimer; interval: 400; onTriggered: win._calVisible = false }

            Connections {
                target: Visibilities
                function onCalendarChanged() {
                    if (Visibilities.calendar) {
                        calHideTimer.stop()
                        win._calVisible = true
                    } else {
                        calHideTimer.restart()
                    }
                }
            }

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "deadlock-calendar"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors { top: true; left: true; right: true }
            margins.top:    43
            implicitHeight: 280

            MouseArea {
                anchors.fill: parent
                z:            0
                enabled:      Visibilities.calendar
                onClicked:    Visibilities.toggle("calendar")
            }

            // Left concave ear: fills the corner between bar bottom and card's left wall.
            // The arc bulges inward (concave from outside) — center at local (0,12).
            Shape {
                z:      1
                x:      card.x - 12
                y:      win.isFocused && Visibilities.calendar ? 0 : -12
                width:  12
                height: 12
                Behavior on y {
                    NumberAnimation {
                        duration: 350; easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }
                ShapePath {
                    fillColor:   card.color
                    strokeColor: "transparent"
                    strokeWidth: 0
                    startX: 0; startY: 0
                    PathArc {
                        x: 12; y: 12
                        radiusX: 12; radiusY: 12
                        direction: PathArc.Clockwise
                    }
                    PathLine { x: 12; y: 0 }
                }
            }

            // Right concave ear: mirror of the left ear.
            Shape {
                z:      1
                x:      card.x + card.width
                y:      win.isFocused && Visibilities.calendar ? 0 : -12
                width:  12
                height: 12
                Behavior on y {
                    NumberAnimation {
                        duration: 350; easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }
                ShapePath {
                    fillColor:   card.color
                    strokeColor: "transparent"
                    strokeWidth: 0
                    startX: 12; startY: 0
                    PathArc {
                        x: 0; y: 12
                        radiusX: 12; radiusY: 12
                        direction: PathArc.Counterclockwise
                    }
                    PathLine { x: 0; y: 0 }
                }
            }

            Rectangle {
                id:     card
                z:      1
                anchors.horizontalCenter: parent.horizontalCenter
                y:      win.isFocused && Visibilities.calendar ? 0 : -(calCard.implicitHeight + 7)
                width:  264
                height: calCard.implicitHeight + 7
                Behavior on y {
                    NumberAnimation {
                        duration:           350
                        easing.type:        Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }
                radius:         12
                topLeftRadius:  0
                topRightRadius: 0
                color:         Colours.m3surfaceContainer
                clip:          true
                layer.enabled: true

                MouseArea { anchors.fill: parent; z: 0 }

                CalendarCard {
                    id: calCard
                    anchors {
                        top:         parent.top
                        left:        parent.left
                        right:       parent.right
                        topMargin:   2
                        leftMargin:  12
                        rightMargin: 12
                        bottomMargin: 5
                    }
                }
            }
        }
    }
}
