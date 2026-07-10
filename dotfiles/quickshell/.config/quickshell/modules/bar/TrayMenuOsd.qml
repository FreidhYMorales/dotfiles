pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import "../../services"
import "../../components"

// Right-click context menu for a system tray icon (BgAppsWidget.qml) — same
// ears+card visual language as the other bar OSDs, but its content comes
// from the tray item's own QsMenuHandle (DBusMenu under the hood) instead
// of anything this project defines.
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

            property bool _menuVisible: false

            Timer { id: menuHideTimer; interval: 400; onTriggered: win._menuVisible = false }

            Connections {
                target: Visibilities
                function onTrayMenuChanged() {
                    if (Visibilities.trayMenu) {
                        menuHideTimer.stop()
                        win._menuVisible = true
                    } else {
                        menuHideTimer.restart()
                    }
                }
            }

            visible: isFocused && win._menuVisible

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "deadlock-tray-menu"
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors { top: true; left: true; right: true }
            margins.top:    43
            implicitHeight: 300

            MouseArea {
                anchors.fill: parent
                z:            0
                enabled:      Visibilities.trayMenu
                onClicked:    Visibilities.toggle("trayMenu")
            }

            QsMenuOpener {
                id: opener
                menu: Visibilities.trayMenuTarget?.menu ?? null
            }

            FontMetrics {
                id:             menuFontMetrics
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 12
            }

            // Widest entry's label, used to size the card to its content
            // instead of a fixed width with empty space on short menus.
            readonly property real _maxEntryTextWidth: {
                const entries = opener.children?.values ?? []
                let max = 0
                for (let i = 0; i < entries.length; i++) {
                    const e = entries[i]
                    if (e.isSeparator) continue
                    const label = (e.checkState === Qt.Checked ? "✓ " : "") + e.text
                    const w = menuFontMetrics.advanceWidth(label)
                    if (w > max) max = w
                }
                return max
            }

            // Left ear
            Shape {
                z: 1
                x: card.x - 12
                y: win.isFocused && Visibilities.trayMenu ? 0 : -12
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
                y: win.isFocused && Visibilities.trayMenu ? 0 : -12
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
                           Visibilities.trayMenuIconX - width / 2,
                           win.width - width - 8
                       ))
                y:      win.isFocused && Visibilities.trayMenu ? 0 : -(menuColumn.implicitHeight + 8)
                Behavior on y {
                    NumberAnimation { duration: 350; easing.type: Easing.BezierSpline
                                      easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0] }
                }
                width:          Math.max(120, Math.min(320, win._maxEntryTextWidth + 48))
                height:         menuColumn.implicitHeight + 8
                radius:         12
                topLeftRadius:  0
                topRightRadius: 0
                color:          Colours.m3surfaceContainer
                clip:           true
                layer.enabled:  true
                Behavior on color { CAnim {} }
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                MouseArea { anchors.fill: parent; z: 0 }

                Column {
                    id: menuColumn
                    anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 4 }

                    Repeater {
                        model: opener.children?.values ?? []
                        delegate: Item {
                            id: entryDelegate
                            required property var modelData
                            width:  menuColumn.width
                            height: modelData.isSeparator ? 9 : 30

                            Rectangle {
                                visible: entryDelegate.modelData.isSeparator
                                anchors { left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                height: 1
                                color:  Colours.mid(Colours.m3surfaceContainer, Colours.m3surfaceContainerHigh)
                            }

                            Rectangle {
                                visible: !entryDelegate.modelData.isSeparator
                                anchors.fill: parent
                                anchors { leftMargin: 4; rightMargin: 4 }
                                radius:  8
                                color:   itemHov.hovered ? Colours.m3surfaceContainerHigh : "transparent"
                                Behavior on color { CAnim {} }

                                Text {
                                    anchors {
                                        left:            parent.left
                                        right:           parent.right
                                        verticalCenter:  parent.verticalCenter
                                        leftMargin:      12
                                        rightMargin:     12
                                    }
                                    text:           (entryDelegate.modelData.checkState === Qt.Checked ? "✓ " : "") + entryDelegate.modelData.text
                                    color:          entryDelegate.modelData.enabled ? Colours.m3onSurface : Colours.m3onSurfaceVariant
                                    font.family:    "Iosevka Term Nerd Font"
                                    font.pixelSize: 12
                                    elide:          Text.ElideRight
                                    Behavior on color { CAnim {} }
                                }

                                HoverHandler { id: itemHov; enabled: entryDelegate.modelData.enabled }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled:      entryDelegate.modelData.enabled
                                    cursorShape:  Qt.PointingHandCursor
                                    onClicked: {
                                        entryDelegate.modelData.triggered()
                                        Visibilities.toggle("trayMenu")
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
