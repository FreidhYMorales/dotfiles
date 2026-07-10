pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import "../../services"
import "../../components"

// Right-click picker for RecorderWidget — screen/region/window. Unlike
// BatteryProfileOsd this isn't a persistent "current mode" selector: each
// segment is a one-shot action (start a recording in that mode) and the OSD
// closes immediately after, so there's no sliding indicator to keep in sync
// with an "active" state — just a brief click flash for feedback.
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

            property bool _visible: false

            Timer { id: hideTimer; interval: 400; onTriggered: win._visible = false }

            Connections {
                target: Visibilities
                function onRecorderModeOsdChanged() {
                    if (Visibilities.recorderModeOsd) {
                        hideTimer.stop()
                        win._visible = true
                    } else {
                        hideTimer.restart()
                    }
                }
            }

            visible: isFocused && win._visible

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "deadlock-recorder-mode"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors { top: true; left: true; right: true }
            margins.top:    43
            implicitHeight: 60

            MouseArea {
                anchors.fill: parent
                z:            0
                enabled:      Visibilities.recorderModeOsd
                onClicked:    Visibilities.toggle("recorderModeOsd")
            }

            // Left ear
            Shape {
                z: 1
                x: card.x - 12
                y: win.isFocused && Visibilities.recorderModeOsd ? 0 : -12
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
                y: win.isFocused && Visibilities.recorderModeOsd ? 0 : -12
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
                           Visibilities.recorderOsdCenterX - width / 2,
                           win.width - width - 8
                       ))
                y:     win.isFocused && Visibilities.recorderModeOsd ? 0 : -39
                Behavior on y {
                    NumberAnimation { duration: 350; easing.type: Easing.BezierSpline
                                      easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0] }
                }
                width:          pill.width + 14
                height:         39
                radius:         12
                topLeftRadius:  0
                topRightRadius: 0
                color:          win.colors.m3surfaceContainer
                layer.enabled:  true
                Behavior on color { CAnim {} }

                MouseArea { anchors.fill: parent; z: 0 }

                Rectangle {
                    id:      pill
                    anchors.centerIn: parent
                    width:   segW * 3
                    height:  segH
                    radius:  height / 2
                    color:   win.colors.m3surfaceContainerHigh
                    Behavior on color { CAnim {} }

                    readonly property int segW: 52
                    readonly property int segH: 32
                    readonly property var modes:  ["screen", "region", "window"]
                    readonly property var labels: ["", "󱣵", "󱣴"]

                    Row {
                        anchors.fill: parent

                        Repeater {
                            model: pill.labels

                            delegate: Item {
                                id: segment
                                required property string modelData
                                required property int    index
                                width:  pill.segW
                                height: pill.segH

                                property bool _flash: false
                                Timer { id: flashTimer; interval: 150; onTriggered: segment._flash = false }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    radius: height / 2
                                    color:  segment._flash ? win.colors.m3primary : "transparent"
                                    Behavior on color { CAnim {} }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text:           segment.modelData
                                    font.family:    "Iosevka Term Nerd Font"
                                    font.pixelSize: 14
                                    color: segment._flash ? win.colors.m3onPrimary : win.colors.m3onSurface
                                    Behavior on color { CAnim {} }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape:  Qt.PointingHandCursor
                                    onClicked: {
                                        segment._flash = true
                                        flashTimer.restart()
                                        const mode = pill.modes[segment.index]
                                        if (mode === "screen")      Recorder.startScreen()
                                        else if (mode === "region") Recorder.startRegion()
                                        else if (mode === "window") Recorder.startWindow()
                                        Visibilities.recorderModeOsd = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
