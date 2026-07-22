pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "../../services"
import "../../components"

// Shows the system tray (StatusNotifierItem) instead of open windows —
// apps that close their window but keep running in the background (e.g.
// Discord/Vesktop minimized to tray) have no Hyprland toplevel at all, so
// that's the only data source that can actually see them.
Item {
    id: root

    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var colors: Colours.palette

    // Stays expanded while the right-click menu is open, not just on hover —
    // otherwise moving the mouse down into the popup would collapse the
    // pill (and its ear/card anchor point) out from under it.
    implicitWidth:  (hov.hovered || Visibilities.trayMenu) ? innerRow.implicitWidth + 16 : 26
    implicitHeight: 26
    clip: true

    Behavior on implicitWidth { Anim { type: Anim.Enter } }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color:        root.colors.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.mid(root.colors.m3surfaceContainer, root.colors.m3surfaceContainerHigh)
        Behavior on color { CAnim {} }
    }

    HoverHandler { id: hov }

    Row {
        id: innerRow
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 8
        layoutDirection: Qt.RightToLeft

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           "‹"
            color:          root.colors.m3onSurface
            font.family:    Style.fontFamily
            font.pixelSize: 16
            Behavior on color { CAnim {} }
        }

        Repeater {
            model: SystemTray.items.values
            delegate: Item {
                id: trayDelegate
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                width:  16
                height: 16

                // Some apps (confirmed: Vesktop) fail the IconName D-Bus
                // property fetch (QDBusError "error occurred in Get") —
                // modelData.icon stays empty with no error signal Image can
                // react to, so it silently renders nothing. Fall back to
                // the first letter of the item's title/id instead of a
                // blank gap.
                Image {
                    anchors.fill: parent
                    visible:    source !== ""
                    source:     trayDelegate.modelData.icon
                    sourceSize: Qt.size(16, 16)
                }

                Rectangle {
                    anchors.fill: parent
                    radius:  height / 2
                    visible: trayDelegate.modelData.icon === ""
                    color:   root.colors.m3primaryContainer

                    Text {
                        anchors.centerIn: parent
                        text: (trayDelegate.modelData.title || trayDelegate.modelData.id || "?").charAt(0).toUpperCase()
                        color:          root.colors.m3onPrimaryContainer
                        font.family:    Style.fontFamily
                        font.pixelSize: 9
                        font.weight:    Font.Bold
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            Visibilities.trayMenuIconX  = trayDelegate.mapToItem(null, trayDelegate.width / 2, 0).x
                            Visibilities.trayMenuTarget = trayDelegate.modelData
                            Visibilities.toggle("trayMenu")
                        } else {
                            trayDelegate.modelData.activate()
                        }
                    }
                }
            }
        }
    }
}
