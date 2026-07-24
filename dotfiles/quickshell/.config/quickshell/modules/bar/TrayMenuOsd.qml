pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"
import "../../components"

// Right-click context menu for a system tray icon (BgAppsWidget.qml) — same
// ears+card visual language as the other bar OSDs, but its content comes
// from the tray item's own QsMenuHandle (DBusMenu under the hood) instead
// of anything this project defines.
MonitorOsdWindow {
    id: osd

    namespace:  "deadlock-tray-menu"
    osdHeight:  300
    osdVisible: _menuVisible

    property bool _menuVisible: false
    Timer { id: menuHideTimer; interval: 400; onTriggered: osd._menuVisible = false }

    Connections {
        target: Visibilities
        function onTrayMenuChanged() {
            if (Visibilities.trayMenu) {
                menuHideTimer.stop()
                osd._menuVisible = true
            } else {
                menuHideTimer.restart()
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
                enabled:      Visibilities.trayMenu
                onClicked:    Visibilities.toggle("trayMenu")
            }

            QsMenuOpener {
                id: opener
                menu: Visibilities.trayMenuTarget?.menu ?? null
            }

            FontMetrics {
                id:             menuFontMetrics
                font.family:    Style.fontFamily
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

            Rectangle {
                id:    card
                z:     1
                x:     Math.max(10, Math.min(
                           Visibilities.trayMenuIconX - width / 2,
                           win.width - width - 10
                       ))
                y:      win.isFocused && Visibilities.trayMenu ? 0 : -(menuColumn.implicitHeight + 16)
                Behavior on y {
                    NumberAnimation { duration: 350; easing.type: Easing.BezierSpline
                                      easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0] }
                }
                width:          Math.max(120, Math.min(320, contentRoot._maxEntryTextWidth + 48))
                height:         menuColumn.implicitHeight + 16
                radius: Style.cornerRadius
                color:          win.colors.m3surfaceContainer
                border.width: 2
                border.color: Qt.alpha(win.colors.m3primary, 0.9)
                clip:           true
                layer.enabled:  true
                Behavior on color { CAnim {} }
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }


                MouseArea { anchors.fill: parent; z: 0 }

                Column {
                    id: menuColumn
                    anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 8 }

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
                                color:  Colours.mid(win.colors.m3surfaceContainer, win.colors.m3surfaceContainerHigh)
                            }

                            StateLayer {
                                visible: !entryDelegate.modelData.isSeparator
                                anchors.fill: parent
                                anchors { leftMargin: 4; rightMargin: 4 }
                                radius:       Style.cornerRadius
                                tintColor:    win.colors.m3surfaceContainerHigh
                                hoverOpacity: 1.0
                                enabled:      entryDelegate.modelData.enabled
                                cursorShape:  Qt.PointingHandCursor
                                onClicked: {
                                    entryDelegate.modelData.triggered()
                                    Visibilities.toggle("trayMenu")
                                }

                                Text {
                                    anchors {
                                        left:            parent.left
                                        right:           parent.right
                                        verticalCenter:  parent.verticalCenter
                                        leftMargin:      12
                                        rightMargin:     12
                                    }
                                    text:           (entryDelegate.modelData.checkState === Qt.Checked ? "✓ " : "") + entryDelegate.modelData.text
                                    color:          entryDelegate.modelData.enabled ? win.colors.m3onSurface : win.colors.m3onSurfaceVariant
                                    font.family:    Style.fontFamily
                                    font.pixelSize: 12
                                    elide:          Text.ElideRight
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
