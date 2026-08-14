pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Controls
import "../../services"
import "../../components"
import "../notifications"

Item {
    id: root

    property bool open:      false
    property bool panelOpen: false
    property int  _stage:    0

    readonly property real _profileH: profileSec.implicitHeight

    HoverHandler {
        onHoveredChanged: hovered ? dashCloseTimer.stop() : dashCloseTimer.restart()
    }

    Connections {
        target: Visibilities
        function onDashboardChanged() {
            if (Visibilities.dashboard) {
                dashCloseTimer.stop()
                closeTimer.stop()
                cs1.stop(); cs2.stop(); cs3.stop(); cs4.stop()
                root.open      = true
                root.panelOpen = false
                root._stage    = 0
                openTimer.restart()
            } else {
                dashCloseTimer.stop()
                openTimer.stop()
                s1.stop(); s2.stop(); s3.stop()
                cs1.restart(); cs2.restart(); cs3.restart(); cs4.restart()
                closeTimer.restart()
            }
        }
    }

    Timer { id: openTimer;  interval: 16;  onTriggered: { root.panelOpen = true; s1.restart(); s2.restart(); s3.restart() } }
    Timer { id: closeTimer; interval: 540; onTriggered: root.open = false }
    Timer { id: dashCloseTimer; interval: 1000; onTriggered: Visibilities.dashboard = false }

    Timer { id: s1;  interval: 140; onTriggered: root._stage = 1 }
    Timer { id: s2;  interval: 250; onTriggered: root._stage = 2 }
    Timer { id: s3;  interval: 360; onTriggered: root._stage = 3 }

    Timer { id: cs1; interval: 10;  onTriggered: { if (root._stage > 2) root._stage = 2 } }
    Timer { id: cs2; interval: 120; onTriggered: { if (root._stage > 1) root._stage = 1 } }
    Timer { id: cs3; interval: 230; onTriggered: { if (root._stage > 0) root._stage = 0 } }
    Timer { id: cs4; interval: 340; onTriggered: root.panelOpen = false }

    // ── Profile panel — connected to bar, drops from top ──
    Capsule {
        id:            panel
        anchors.right: parent.right
        width:         root.width
        height:        root._profileH
        y:             root.panelOpen ? 0 : -root._profileH
        Behavior on y {
            NumberAnimation {
                duration: 150; easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
            }
        }
        color:          Colours.m3surfaceContainer
        clip:           true
        layer.enabled:  true

        MouseArea { anchors.fill: parent }

        ProfileSection {
            id:    profileSec
            width: parent.width
        }

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color:  Qt.alpha(Colours.m3outlineVariant, 0.25)
            Behavior on color { CAnim {} }
        }
    }

    // ── Independent capsules — same y-slide animation as profile panel ──
    ScrollView {
        anchors {
            top:        parent.top
            topMargin:  root._profileH + 8
            bottom:     parent.bottom
            left:       parent.left
            right:      parent.right
        }
        clip:         true
        contentWidth: availableWidth
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        Column {
            width:         parent.width
            spacing:       8
            bottomPadding: 10

            // Capsule 1: Weather
            Item {
                width:  parent.width
                height: cap1.height
                clip:   true

                Capsule {
                    id:     cap1
                    width:  parent.width
                    height: 116
                    y:      root._stage >= 1 ? 0 : -root.height
                    Behavior on y {
                        NumberAnimation {
                            duration: 100; easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                        }
                    }

                    WeatherTab { anchors.fill: parent }
                }
            }

            // Capsule 2: Battery + Performance
            Item {
                width:  parent.width
                height: cap2.height
                clip:   true

                Capsule {
                    id:     cap2
                    width:  parent.width
                    height: cap2Col.implicitHeight
                    y:      root._stage >= 2 ? 0 : -root.height
                    Behavior on y {
                        NumberAnimation {
                            duration: 100; easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                        }
                    }

                    Column {
                        id:    cap2Col
                        width: parent.width

                        BatterySection {}

                        Rectangle {
                            width:  parent.width
                            height: 1
                            color:  Qt.alpha(Colours.m3outlineVariant, 0.25)
                            Behavior on color { CAnim {} }
                        }

                        PerformanceSection {}
                    }
                }
            }

            // Capsule 3: Music (only when a player is active)
            Item {
                visible: Mpris.hasPlayer
                width:   parent.width
                height:  cap3.height
                clip:    true

                Capsule {
                    id:     cap3
                    width:  parent.width
                    height: mediaSec.implicitHeight
                    y:      root._stage >= 3 ? 0 : -root.height
                    Behavior on y {
                        NumberAnimation {
                            duration: 100; easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                        }
                    }

                    MediaSection {
                        id:    mediaSec
                        width: parent.width
                    }
                }
            }
        }
    }
}
