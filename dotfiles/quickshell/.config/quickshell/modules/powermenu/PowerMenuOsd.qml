pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
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

                // Pill wrapper
                Item {
                    id: pillContainer
                    anchors.centerIn: parent
                    width:  pill.implicitWidth
                    height: pill.implicitHeight

                    scale:   Visibilities.powerMenu ? 1.0 : 0.88
                    opacity: Visibilities.powerMenu ? 1.0 : 0.0
                    Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    // Select the first button on open, clear on close — Enter
                    // needs a valid index to activate, and required arrowing
                    // first before it worked at all.
                    Connections {
                        target: Visibilities
                        function onPowerMenuChanged() {
                            pill.selectedIndex = Visibilities.powerMenu ? 0 : -1
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

                        radius: Style.cornerRadius
                        color:  Colours.m3surfaceContainerHigh
                        border.width: 2
                        border.color: Qt.alpha(Colours.m3primary, 0.9)
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
                            // Capture before toggling — closing the menu resets
                            // selectedIndex synchronously via the Connections below.
                            const cmd = buttons[selectedIndex].cmd
                            Visibilities.toggle("powerMenu")
                            Quickshell.execDetached(cmd)
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

                                    // Segment divider — hidden after the last button
                                    Rectangle {
                                        visible: index < pill.buttons.length - 1
                                        anchors {
                                            left:           parent.right
                                            leftMargin:     pill.spacing / 2 - 0.5
                                            verticalCenter: parent.verticalCenter
                                        }
                                        width:  1
                                        height: pill.btnSize * 0.5
                                        color:  Qt.alpha(Colours.m3outlineVariant, 0.3)
                                        Behavior on color { CAnim {} }
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
