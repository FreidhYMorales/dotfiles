pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "../../services"
import "../../components"

// Power menu — fullscreen scrim + centered pill with 5 icon buttons.
// IPC:  qs ipc call powermenu toggle
// Key:  CTRL + ALT + DELETE (keybinds.lua)
// Blur (rule.lua):
//   hl.layer_rule({ match = { namespace = "qs-powermenu" }, blur = true })
//   hl.layer_rule({ match = { namespace = "qs-powermenu" }, ignore_alpha = 0.2 })

Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: screenScope
        required property ShellScreen modelData

        PanelWindow {
            id: win
            screen: screenScope.modelData
            color:  "transparent"
            visible: Visibilities.powerMenu
            onVisibleChanged: if (visible) keyFocus.forceActiveFocus()

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "qs-powermenu"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors { top: true; left: true; right: true; bottom: true }

            // Keyboard handler — must live on a focused Item, not PanelWindow
            Item {
                id: keyFocus
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: Visibilities.toggle("powerMenu")
                Keys.onLeftPressed: {
                    if (pill.selectedIndex <= 0) pill.selectedIndex = pill.buttons.length - 1
                    else pill.selectedIndex--
                }
                Keys.onRightPressed: {
                    if (pill.selectedIndex >= pill.buttons.length - 1) pill.selectedIndex = 0
                    else pill.selectedIndex++
                }
                Keys.onReturnPressed: pill.activateSelected()
                Keys.onSpacePressed:  pill.activateSelected()

                // Dark scrim — click outside dismisses
                Rectangle {
                    anchors.fill: parent
                    color:   Qt.rgba(0, 0, 0, 0.55)
                    opacity: Visibilities.powerMenu ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Visibilities.toggle("powerMenu")
                    }
                }

                // Pill + animated border wrapper
                Item {
                    id: pillContainer
                    anchors.centerIn: parent
                    width:  pill.implicitWidth
                    height: pill.implicitHeight

                    scale:   Visibilities.powerMenu ? 1.0 : 0.88
                    opacity: Visibilities.powerMenu ? 1.0 : 0.0
                    Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    // Reset selection when menu closes
                    Connections {
                        target: Visibilities
                        function onPowerMenuChanged() {
                            if (!Visibilities.powerMenu) pill.selectedIndex = -1
                        }
                    }

                    Rectangle {
                        id: pill
                        anchors.fill: parent

                        readonly property int btnSize:  64
                        readonly property int hPad:     16
                        readonly property int vPad:     14
                        readonly property int spacing:  6

                        implicitWidth:  hPad * 2 + btnSize * 5 + spacing * 4
                        implicitHeight: vPad * 2 + btnSize

                        radius: height / 2
                        color:  Colours.m3surfaceContainerHigh
                        border.width: 1
                        border.color: Qt.alpha(Colours.m3onSurface, 0.10)
                        Behavior on color { CAnim {} }

                        property int selectedIndex: -1

                        readonly property var buttons: [
                            { icon: "󰐥", cmd: ["systemctl", "poweroff"] },
                            { icon: "󰑩", cmd: ["systemctl", "reboot"] },
                            { icon: "󰒲", cmd: ["systemctl", "suspend"] },
                            { icon: "󰌾", cmd: ["qs", "ipc", "-p", Quickshell.shellDir, "call", "lock", "lock"] },
                            { icon: "󰍃", cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] }
                        ]

                        function activateSelected() {
                            if (selectedIndex < 0 || selectedIndex >= buttons.length) return
                            Visibilities.toggle("powerMenu")
                            Quickshell.execDetached(buttons[selectedIndex].cmd)
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: pill.spacing

                            Repeater {
                                model: pill.buttons
                                delegate: PowerMenuButton {
                                    required property var modelData
                                    required property int index
                                    icon:       modelData.icon
                                    buttonSize: pill.btnSize
                                    selected:   index === pill.selectedIndex
                                    onActivated: {
                                        Visibilities.toggle("powerMenu")
                                        Quickshell.execDetached(modelData.cmd)
                                    }
                                }
                            }
                        }
                    }

                    // Animated glow — segment travels around the pill as a soft streak.
                    // Canvas is intentionally larger than the pill (gm px on each side)
                    // so the MultiEffect blur at the curved ends is never clipped by
                    // the Canvas bounding box.
                    Canvas {
                        id: borderCanvas
                        readonly property int gm: 20

                        anchors.fill:    parent
                        anchors.margins: -gm

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur:        0.8
                            blurMax:     20
                        }

                        property color strokeColor: Colours.m3primary
                        onStrokeColorChanged: requestPaint()

                        readonly property real pillW: width  - gm * 2
                        readonly property real pillH: height - gm * 2
                        readonly property real perimeter: 2 * (pillW - pillH) + Math.PI * pillH

                        property real dashOffset: 0
                        onDashOffsetChanged: requestPaint()

                        NumberAnimation on dashOffset {
                            from:        0
                            to:          -borderCanvas.perimeter
                            duration:    2400
                            loops:       Animation.Infinite
                            running:     Visibilities.powerMenu
                            easing.type: Easing.Linear
                        }

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()

                            var m  = gm
                            var w  = pillW
                            var h  = pillH
                            var r  = h / 2
                            var segLen = 110

                            ctx.strokeStyle = Qt.rgba(
                                strokeColor.r, strokeColor.g, strokeColor.b, 1.0)
                            ctx.lineWidth = 3.5
                            ctx.lineCap   = "round"
                            ctx.setLineDash([segLen, perimeter - segLen])
                            ctx.lineDashOffset = dashOffset

                            ctx.beginPath()
                            ctx.moveTo(m + r,     m)
                            ctx.lineTo(m + w - r, m)
                            ctx.arc(m + w - r, m + r, r, -Math.PI / 2,     Math.PI / 2,      false)
                            ctx.lineTo(m + r,  m + h)
                            ctx.arc(m + r,     m + r, r,  Math.PI / 2, 3 * Math.PI / 2,      false)
                            ctx.closePath()
                            ctx.stroke()
                        }
                    }
                }
            }
        }
    }
}
