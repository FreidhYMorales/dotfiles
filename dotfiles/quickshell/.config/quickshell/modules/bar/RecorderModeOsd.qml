pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"
import "../../components"

// Right-click picker for RecorderWidget — screen/region/window. Unlike
// BatteryProfileOsd this isn't a persistent "current mode" selector: each
// segment is a one-shot action (start a recording in that mode) and the OSD
// closes immediately after — but the sliding indicator (same pattern as
// BatteryProfileOsd) still tracks Recorder.mode, remembering the last mode
// that actually started, so it's visible next time the picker opens and
// drives the widget's left-click default (see RecorderWidget.qml).
MonitorOsdWindow {
    id: osd

    namespace:  "deadlock-recorder-mode"
    osdHeight:  60
    osdVisible: _visible

    property bool _visible: false
    Timer { id: hideTimer; interval: 400; onTriggered: osd._visible = false }

    Connections {
        target: Visibilities
        function onRecorderModeOsdChanged() {
            if (Visibilities.recorderModeOsd) {
                hideTimer.stop()
                osd._visible = true
            } else {
                hideTimer.restart()
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
                enabled:      Visibilities.recorderModeOsd
                onClicked:    Visibilities.toggle("recorderModeOsd")
            }

            Rectangle {
                id:    card
                z:     1
                x:     Math.max(10, Math.min(
                           Visibilities.recorderOsdCenterX - width / 2,
                           win.width - width - 10
                       ))
                y:     win.isFocused && Visibilities.recorderModeOsd ? 0 : -48
                Behavior on y {
                    NumberAnimation { duration: 350; easing.type: Easing.BezierSpline
                                      easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0] }
                }
                width:          pill.width + 14
                height:         48
                radius: Style.cornerRadius
                color:          win.colors.m3surfaceContainer
                border.width: 2
                border.color: Qt.alpha(win.colors.m3primary, 0.9)
                layer.enabled:  true
                Behavior on color { CAnim {} }


                MouseArea { anchors.fill: parent; z: 0 }

                Rectangle {
                    id:      pill
                    anchors.centerIn: parent
                    width:   segW * 3
                    height:  segH
                    radius: Style.cornerRadius
                    color:   win.colors.m3surfaceContainerHigh
                    Behavior on color { CAnim {} }

                    readonly property int segW: 52
                    readonly property int segH: 32
                    readonly property var modes:  ["screen", "region", "window"]
                    readonly property int selectedIndex: {
                        const i = modes.indexOf(Recorder.mode)
                        return i >= 0 ? i : 0
                    }
                    readonly property var labels: ["", "󱣵", "󱣴"]

                    // Sliding indicator — remembers the last mode a recording
                    // actually started in, so the widget's left click has a
                    // sensible default instead of always full-screen.
                    Rectangle {
                        width:  pill.segW - 4
                        height: pill.height - 4
                        radius: Style.cornerRadius
                        color:  win.colors.m3primary
                        anchors.verticalCenter: parent.verticalCenter
                        x: pill.selectedIndex * pill.segW + 2
                        Behavior on x     { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                        Behavior on color { CAnim {} }
                    }

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
                                    radius: Style.cornerRadius
                                    color:  segment._flash ? win.colors.m3primary : "transparent"
                                    Behavior on color { CAnim {} }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text:           segment.modelData
                                    font.family:    Style.fontFamily
                                    font.pixelSize: 14
                                    color: segment._flash || pill.selectedIndex === segment.index
                                               ? win.colors.m3onPrimary
                                               : win.colors.m3onSurface
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
