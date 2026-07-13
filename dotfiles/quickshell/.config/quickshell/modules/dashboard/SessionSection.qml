import Quickshell
import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    implicitHeight: 80
    implicitWidth:  parent?.width ?? 300

    // Button definition: icon (Nerd Font), label, and either:
    //   cmd    — execDetached command array
    //   toggle — Visibilities panel name to toggle instead
    readonly property var buttons: [
        { icon: "󰐥", label: "Power",   toggle: "powerMenu"                              },
        { icon: "󰑩", label: "Reboot",  cmd: ["systemctl", "reboot"]                    },
        { icon: "󰒲", label: "Suspend", cmd: ["systemctl", "suspend"]                   },
        { icon: "󰌾", label: "Lock",    cmd: ["qs", "ipc", "-p", Quickshell.shellDir, "call", "lock", "lock"] },
        { icon: "󰍃", label: "Logout",  cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] }
    ]

    Row {
        anchors.centerIn: parent
        spacing:          (root.width - 5 * 48) / 6   // evenly distributed

        Repeater {
            model: root.buttons

            delegate: Item {
                id:     btnDelegate
                required property var modelData

                width:  48
                height: 64

                HoverHandler { id: hov }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter:   parent.verticalCenter
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text:           btnDelegate.modelData.icon
                        color:          hov.hovered ? Colours.m3primary : Colours.m3onSurfaceVariant
                        font.family:    "Iosevka Term Nerd Font"
                        font.pixelSize: 24
                        scale:          hov.hovered ? 1.3 : 1.0
                        transformOrigin: Item.Center
                        Behavior on color { CAnim {} }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text:           btnDelegate.modelData.label
                        color:          Colours.m3onSurfaceVariant
                        font.family:    "Iosevka Term Nerd Font"
                        font.pixelSize: 9
                        Behavior on color { CAnim {} }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        if (btnDelegate.modelData.toggle) {
                            Visibilities.closeAll()
                            Visibilities.toggle(btnDelegate.modelData.toggle)
                        } else {
                            Quickshell.execDetached(btnDelegate.modelData.cmd)
                            Visibilities.toggle("dashboard")
                        }
                    }
                }
            }
        }
    }
}
