pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"
import "../../components"

MonitorOsdWindow {
    id: osd

    namespace:  "deadlock-battery-profile"
    osdHeight:  60
    osdVisible: _batVisible

    property bool _batVisible: false
    Timer { id: batHideTimer;  interval: 400;  onTriggered: osd._batVisible = false }
    Timer { id: batCloseTimer; interval: 1000; onTriggered: Visibilities.batteryProfile = false }

    function pauseAutoClose()  { batCloseTimer.stop() }
    function resumeAutoClose() { batCloseTimer.restart() }

    Connections {
        target: Visibilities
        function onBatteryProfileChanged() {
            if (Visibilities.batteryProfile) {
                batCloseTimer.stop()
                batHideTimer.stop()
                osd._batVisible = true
            } else {
                batCloseTimer.stop()
                batHideTimer.restart()
            }
        }
    }

    content: Component {
        Item {
            id: contentRoot
            anchors.fill: parent
            property PanelWindow win: null
            property var osd: null

            MouseArea {
                anchors.fill: parent
                z:            0
                enabled:      Visibilities.batteryProfile
                onClicked:    Visibilities.toggle("batteryProfile")
            }

            Rectangle {
                id:    card
                z:     1
                x:     Math.max(10, Math.min(
                           Visibilities.batteryBarCenterX - width / 2 - 6,
                           win.width - width - 10
                       ))
                y:     win.isFocused && Visibilities.batteryProfile ? 0 : -48
                Behavior on y {
                    NumberAnimation { duration: 350; easing.type: Easing.BezierSpline
                                      easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0] }
                }
                width:          228
                height:         48
                radius: Style.cornerRadius
                color:          win.colors.m3surfaceContainer
                border.width: 2
                border.color: Qt.alpha(win.colors.m3primary, 0.9)
                layer.enabled:  true
                Behavior on color { CAnim {} }


                HoverHandler {
                    onHoveredChanged: hovered ? osd.pauseAutoClose() : osd.resumeAutoClose()
                }

                MouseArea { anchors.fill: parent; z: 0 }

                // Segmented pill selector + caffeine toggle
                Row {
                    anchors.centerIn: parent
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
                        radius: Style.cornerRadius
                        color:  win.colors.m3surfaceContainerHigh
                        Behavior on color { CAnim {} }

                        // Sliding indicator
                        Rectangle {
                            id:      indicator
                            width:   parent.parent.segW - 4
                            height:  parent.height - 4
                            radius: Style.cornerRadius
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
                    radius: Style.cornerRadius
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
