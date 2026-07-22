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

            property var    toastNotif: null
            property bool   showing:    false  // intent — set by notification watcher
            property bool   cardOpen:   false  // actual card state — driven by sequenced timers
            property string _lastId:    ""

            visible: isFocused && toastNotif !== null

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "deadlock-notif-toast"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors { top: true; left: true; right: true }
            margins.top: 43

            implicitHeight: 160

            // ── Animation sequence ────────────────────────────────────────
            //
            // Appear:  corner flattens (t=0) → card opens (t=60ms)
            // Dismiss: corner rounds   (t=0) → card closes (t=200ms) → window hides (t=650ms)

            onShowingChanged: {
                if (showing) {
                    // Appear: corner flattens (t=0) → card opens (t=70ms)
                    dismissDelay.stop()
                    cleanupTimer.stop()
                    Visibilities.notifToast = true
                    appearDelay.restart()
                } else {
                    // Dismiss (mirror): card closes (t=0) → corner rounds (t=70ms)
                    appearDelay.stop()
                    win.cardOpen = false
                    dismissDelay.restart()
                    cleanupTimer.restart()
                }
            }

            // Appear: corner flattens and card opens almost simultaneously (1ms offset)
            Timer { id: appearDelay;  interval: 1;   onTriggered: win.cardOpen = true }
            // Dismiss: wait for card animation to finish (350ms), then round corner
            Timer { id: dismissDelay; interval: 350; onTriggered: Visibilities.notifToast = false }
            // 350ms (card) + 350ms (corner) + 50ms buffer
            Timer { id: cleanupTimer; interval: 750; onTriggered: win.toastNotif = null }

            // Auto-dismiss after expireTimeout
            Timer {
                id: dismissTimer
                onTriggered: win.showing = false
            }

            // ── Ear left ─────────────────────────────────────────────────
            Shape {
                z: 1
                x: card.x - 12
                y: win.isFocused && win.cardOpen ? 0 : -12
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
                    strokeColor: "transparent"; strokeWidth: 0
                    startX: 0; startY: 0
                    PathArc  { x: 12; y: 12; radiusX: 12; radiusY: 12; direction: PathArc.Clockwise }
                    PathLine { x: 12; y: 0 }
                }
            }

            // ── Toast card ────────────────────────────────────────────────
            Rectangle {
                id: card
                z:  1

                anchors { right: parent.right; rightMargin: 8 }
                width:  360
                height: inner.implicitHeight + 28
                y:      win.isFocused && win.cardOpen ? 0 : -(inner.implicitHeight + 28)
                Behavior on y {
                    NumberAnimation {
                        duration: 350; easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                    }
                }

                topLeftRadius:  0
                topRightRadius: 0
                radius: 12

                color: Colours.m3surfaceContainer
                Behavior on color { CAnim {} }

                clip:          true
                layer.enabled: true

                HoverHandler {
                    onHoveredChanged: hovered ? dismissTimer.stop() : dismissTimer.restart()
                }

                Column {
                    id: inner
                    anchors {
                        top:    parent.top;   topMargin:   14
                        left:   parent.left;  leftMargin:  16
                        right:  parent.right; rightMargin: 16
                    }
                    spacing: 6

                    opacity: win.cardOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }

                    Item {
                        width:  parent.width
                        height: 20

                        Item {
                            id: iconCircle
                            width: 20; height: 20
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color:  Colours.m3primaryContainer
                                Behavior on color { CAnim {} }
                            }

                            Image {
                                id: appIconImg
                                anchors { fill: parent; margins: 2 }
                                source:   win.toastNotif?.appIcon ? ("file://" + win.toastNotif.appIcon) : ""
                                fillMode: Image.PreserveAspectFit
                                smooth:   true; mipmap: true
                                visible:  status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible:        !appIconImg.visible
                                text:           (win.toastNotif?.appName ?? "?").charAt(0).toUpperCase()
                                color:          Colours.m3onPrimaryContainer
                                font.family:    Style.fontFamily
                                font.pixelSize: 10
                                font.weight:    Font.Medium
                                Behavior on color { CAnim {} }
                            }
                        }

                        Text {
                            anchors {
                                left:           iconCircle.right; leftMargin:  8
                                right:          dismissBtn.left;  rightMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            text:           win.toastNotif?.appName ?? ""
                            color:          Colours.m3onSurfaceVariant
                            font.family:    Style.fontFamily
                            font.pixelSize: 11
                            elide:          Text.ElideRight
                            Behavior on color { CAnim {} }
                        }

                        Item {
                            id: dismissBtn
                            width: 20; height: 20
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }

                            Text {
                                anchors.centerIn: parent
                                text:  "󰅖"
                                color: dismissHov.hovered
                                       ? Colours.m3onSurface
                                       : Colours.m3onSurfaceVariant
                                font.family:    Style.fontFamily
                                font.pixelSize: 13
                                Behavior on color { CAnim {} }
                            }

                            HoverHandler { id: dismissHov }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                onClicked: {
                                    dismissTimer.stop()
                                    win.showing = false
                                }
                            }
                        }
                    }

                    Text {
                        width:          parent.width
                        text:           win.toastNotif?.summary ?? ""
                        visible:        text.length > 0
                        color:          Colours.m3onSurface
                        font.family:    Style.fontFamily
                        font.pixelSize: 13
                        font.weight:    Font.Medium
                        wrapMode:       Text.WordWrap
                        maximumLineCount: 2
                        elide:          Text.ElideRight
                        Behavior on color { CAnim {} }
                    }

                    Text {
                        width:          parent.width
                        text:           win.toastNotif?.body ?? ""
                        visible:        text.length > 0
                        color:          Colours.m3onSurfaceVariant
                        font.family:    Style.fontFamily
                        font.pixelSize: 11
                        wrapMode:       Text.WordWrap
                        maximumLineCount: 3
                        elide:          Text.ElideRight
                        Behavior on color { CAnim {} }
                    }
                }
            }

            // ── Notification watcher ──────────────────────────────────────

            Connections {
                target: Visibilities
                function onDashboardChanged() {
                    if (Visibilities.dashboard && win.showing) {
                        dismissTimer.stop()
                        win.showing = false
                    }
                }
            }

            Connections {
                target: Notifs
                function onListChanged() {
                    if (!win.isFocused) return
                    if (Visibilities.silentMode) return
                    if (Visibilities.dashboard) return
                    const list = Notifs.list
                    if (list.length === 0) return
                    const newest = list[0]
                    if (!newest || newest.closed) return
                    if (newest.notificationId === win._lastId) return

                    win._lastId    = newest.notificationId
                    win.toastNotif = newest
                    win.showing    = true
                    dismissTimer.interval = newest.expireTimeout > 0 ? newest.expireTimeout : 5000
                    dismissTimer.restart()
                }
            }
        }
    }
}
