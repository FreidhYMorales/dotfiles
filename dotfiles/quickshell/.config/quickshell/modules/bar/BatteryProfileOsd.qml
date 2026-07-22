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
            // Per-monitor palette (bar/panels only — see Colours.paletteFor).
            readonly property var colors: Colours.paletteFor(screenScope.modelData.name)

            property bool _batVisible: false

            Timer { id: batHideTimer; interval: 400; onTriggered: win._batVisible = false }

            Timer {
                id: batCloseTimer
                interval: 1000
                onTriggered: Visibilities.batteryProfile = false
            }

            Connections {
                target: Visibilities
                function onBatteryProfileChanged() {
                    if (Visibilities.batteryProfile) {
                        batCloseTimer.stop()
                        batHideTimer.stop()
                        win._batVisible = true
                    } else {
                        batCloseTimer.stop()
                        batHideTimer.restart()
                    }
                }
            }

            visible: isFocused && win._batVisible

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "deadlock-battery-profile"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors { top: true; left: true; right: true }
            margins.top:    43
            implicitHeight: 60

            MouseArea {
                anchors.fill: parent
                z:            0
                enabled:      Visibilities.batteryProfile
                onClicked:    Visibilities.toggle("batteryProfile")
            }

            // Left ear
            Shape {
                z: 1
                x: card.x - 12
                y: win.isFocused && Visibilities.batteryProfile ? 0 : -12
                width: 12; height: 12
                Behavior on y {
                    NumberAnimation { duration: 350; easing.type: Easing.BezierSpline
                                      easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0] }
                }
                ShapePath {
                    fillColor: card.color; strokeColor: "transparent"; strokeWidth: 0
                    startX: 0; startY: 0
                    PathArc  { x: 12; y: 12; radiusX: 12; radiusY: 12; direction: PathArc.Clockwise }
                    PathLine { x: 12; y: 0 }
                }
            }

            // Right ear
            Shape {
                z: 1
                x: card.x + card.width
                y: win.isFocused && Visibilities.batteryProfile ? 0 : -12
                width: 12; height: 12
                Behavior on y {
                    NumberAnimation { duration: 350; easing.type: Easing.BezierSpline
                                      easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0] }
                }
                ShapePath {
                    fillColor: card.color; strokeColor: "transparent"; strokeWidth: 0
                    startX: 12; startY: 0
                    PathArc  { x: 0; y: 12; radiusX: 12; radiusY: 12; direction: PathArc.Counterclockwise }
                    PathLine { x: 0; y: 0 }
                }
            }

            Rectangle {
                id:    card
                z:     1
                x:     Math.max(8, Math.min(
                           Visibilities.batteryBarCenterX - width / 2 - 6,
                           win.width - width - 8
                       ))
                y:     win.isFocused && Visibilities.batteryProfile ? 0 : -39
                Behavior on y {
                    NumberAnimation { duration: 350; easing.type: Easing.BezierSpline
                                      easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0] }
                }
                width:          228
                height:         39
                radius:         12
                topLeftRadius:  0
                topRightRadius: 0
                color:          win.colors.m3surfaceContainer
                layer.enabled:  true
                Behavior on color { CAnim {} }

                HoverHandler {
                    onHoveredChanged: hovered ? batCloseTimer.stop() : batCloseTimer.restart()
                }

                MouseArea { anchors.fill: parent; z: 0 }

                // Segmented pill selector + caffeine toggle
                Row {
                    anchors {
                        top:             parent.top
                        topMargin:       2
                        horizontalCenter: parent.horizontalCenter
                    }
                    spacing: 10

                Item {
                    width:  pill.width
                    height: pill.height

                    readonly property var profiles: ["power-saver", "balanced", "performance"]
                    readonly property var labels:   ["", "⚖", "󱓞"]
                    readonly property int selectedIndex: {
                        const i = profiles.indexOf(BatteryProfile.current)
                        return i >= 0 ? i : 1
                    }
                    readonly property int segW: 52
                    readonly property int segH: 32

                    // Outer pill background
                    Rectangle {
                        id:     pill
                        width:  parent.segW * 3
                        height: parent.segH
                        radius: height / 2
                        color:  win.colors.m3surfaceContainerHigh
                        Behavior on color { CAnim {} }

                        // Sliding indicator
                        Rectangle {
                            id:      indicator
                            width:   parent.parent.segW - 4
                            height:  parent.height - 4
                            radius:  height / 2
                            color:   win.colors.m3primary
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.parent.selectedIndex * parent.parent.segW + 2
                            Behavior on x {
                                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                            }
                            Behavior on color { CAnim {} }
                        }

                        // Labels + click areas
                        Row {
                            anchors.fill: parent

                            Repeater {
                                model: parent.parent.parent.labels

                                delegate: Item {
                                    required property string modelData
                                    required property int    index
                                    width:  pill.parent.segW
                                    height: pill.height

                                    Text {
                                        anchors.centerIn: parent
                                        text:           modelData
                                        font.family:    Style.fontFamily
                                        font.pixelSize: 14
                                        color: pill.parent.selectedIndex === index
                                               ? win.colors.m3onPrimary
                                               : win.colors.m3onSurface
                                        Behavior on color { CAnim {} }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked:    BatteryProfile.set(pill.parent.profiles[index])
                                    }
                                }
                            }
                        }
                    }
                }

                // Caffeine mode — inhibits idle (no screensaver/lock/suspend)
                Rectangle {
                    id: caffeineButton
                    width:  32
                    height: pill.height
                    radius: height / 2
                    color:  "transparent"

                    Text {
                        anchors.centerIn: parent
                        text:           IdleManager.caffeineMode ? "󰅶" : "󰛊"
                        font.family:    Style.fontFamily
                        font.pixelSize: 15
                        color: IdleManager.caffeineMode ? win.colors.m3primary : win.colors.m3onSurface
                        Behavior on color { CAnim {} }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    IdleManager.caffeineMode = !IdleManager.caffeineMode
                    }
                }
                }
            }
        }
    }
}
