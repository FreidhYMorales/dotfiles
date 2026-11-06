pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
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
            // Per-monitor palette (bar/panels only — see Colours.paletteFor).
            readonly property var colors: Colours.paletteFor(screenScope.modelData.name)

            property bool _calVisible: false

            visible: isFocused && win._calVisible

            Timer { id: calHideTimer; interval: 400; onTriggered: win._calVisible = false }

            Timer {
                id: calCloseTimer
                interval: 1000
                onTriggered: Visibilities.calendar = false
            }

            Connections {
                target: Visibilities
                function onCalendarChanged() {
                    if (Visibilities.calendar) {
                        calCloseTimer.stop()
                        calHideTimer.stop()
                        win._calVisible = true
                    } else {
                        calCloseTimer.stop()
                        calHideTimer.restart()
                    }
                }
            }

            WlrLayershell.layer:         WlrLayer.Top
            WlrLayershell.namespace:     "deadlock-calendar"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors { top: true; left: true; right: true }
            margins.top:    44
            implicitHeight: 280

            MouseArea {
                anchors.fill: parent
                z:            0
                enabled:      Visibilities.calendar
                onClicked:    Visibilities.toggle("calendar")
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
                radius: Style.cornerRadius
                color:         win.colors.m3surfaceContainer
                border.width: 2
                border.color: Qt.alpha(win.colors.m3primary, 0.9)
                clip:          true
                layer.enabled: true


                HoverHandler {
                    onHoveredChanged: hovered ? calCloseTimer.stop() : calCloseTimer.restart()
                }

                MouseArea { anchors.fill: parent; z: 0 }

                CalendarCard {
                    id: calCard
                    colors: win.colors
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
