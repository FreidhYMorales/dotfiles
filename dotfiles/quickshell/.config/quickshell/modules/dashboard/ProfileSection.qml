import Quickshell
import Quickshell.Io
import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    implicitHeight: rightCol.implicitHeight + 10
    implicitWidth:  parent?.width ?? 300

    property string _uptime: ""
    property string _user:   Quickshell.env("USER")

    readonly property var _powerButtons: [
        { icon: "󰐥", cmd: ["systemctl", "poweroff"]           },
        { icon: "󰑩", cmd: ["systemctl", "reboot"]             },
        { icon: "󰒲", cmd: ["systemctl", "suspend"]            },
        { icon: "󰌾", cmd: ["qs", "ipc", "-p", Quickshell.shellDir, "call", "lock", "lock"] },
        // This Hyprland build routes `dispatch` through a Lua bridge (hl.dispatch) —
        // bare dispatcher names like "exit" are no longer valid, only hl.dsp.* calls.
        { icon: "󰍃", cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] }
    ]

    function _parseUptime(line) {
        const secs = Math.floor(parseFloat(line.trim().split(" ")[0]))
        if (isNaN(secs) || secs <= 0) return ""
        const days  = Math.floor(secs / 86400)
        const hours = Math.floor((secs % 86400) / 3600)
        const mins  = Math.floor((secs % 3600) / 60)
        if (days > 0)  return days  + "d " + hours + "h"
        if (hours > 0) return hours + "h " + mins  + "m"
        return mins + "m"
    }

    Process {
        id: uptimeProc
        command: ["cat", "/proc/uptime"]
        stdout: SplitParser {
            onRead: line => { root._uptime = root._parseUptime(line) }
        }
    }

    Timer {
        interval: 60000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }

    // Avatar (left, vertically centered to the whole capsule)
    Rectangle {
        id:     avatar
        width:  56
        height: 56
        radius: 28
        color:  Colours.m3primaryContainer
        Behavior on color { CAnim {} }

        anchors {
            left:           parent.left
            leftMargin:     12
            verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.centerIn: parent
            text:           root._user.length > 0 ? root._user[0].toUpperCase() : "?"
            color:          Colours.m3onPrimaryContainer
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 22
            font.weight:    Font.Medium
            Behavior on color { CAnim {} }
        }
    }

    // Right column: name + uptime + power pill
    Column {
        id: rightCol
        spacing: 2

        anchors {
            left:           avatar.right
            leftMargin:     12
            right:          parent.right
            rightMargin:    12
            verticalCenter: parent.verticalCenter
        }

        Text {
            text:           root._user
            color:          Colours.m3onSurface
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 16
            font.weight:    Font.Medium
            elide:          Text.ElideRight
            width:          parent.width
            Behavior on color { CAnim {} }
        }

        Text {
            text:           root._uptime.length > 0 ? "up " + root._uptime : "up —"
            color:          Colours.m3onSurfaceVariant
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 11
            Behavior on color { CAnim {} }
        }

        // Power button pill — same fill/border treatment as the bar's pills
        // (workspaces, CPU, RAM, BgApps, clock) for a consistent look.
        Rectangle {
            height: 28
            width:  parent.width
            radius: 14
            color:        Colours.m3surfaceContainerHigh
            border.width: 1
            border.color: Colours.mid(Colours.m3surfaceContainer, Colours.m3surfaceContainerHigh)
            Behavior on color { CAnim {} }

            Row {
                id: powerRow
                anchors {
                    left:           parent.left
                    right:          parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin:     8
                    rightMargin:    8
                }
                spacing: Math.max(0, (width - 5 * 24) / 4)

                Repeater {
                    model: root._powerButtons

                    delegate: Item {
                        id: powerBtn
                        required property var modelData

                        width:  24
                        height: 24
                        anchors.verticalCenter: parent?.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius:       6
                            color:        btnHov.hovered
                                              ? Qt.alpha(Colours.m3onSurface, 0.12)
                                              : "transparent"
                            Behavior on color { CAnim {} }
                        }

                        Text {
                            anchors.centerIn: parent
                            text:           powerBtn.modelData.icon
                            color:          btnHov.hovered
                                                ? Colours.m3onSurface
                                                : Colours.m3onSurfaceVariant
                            font.family:    "Iosevka Term Nerd Font"
                            font.pixelSize: 13
                            Behavior on color { CAnim {} }
                        }

                        HoverHandler { id: btnHov }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(powerBtn.modelData.cmd)
                                Visibilities.toggle("dashboard")
                            }
                        }
                    }
                }
            }
        }
    }
}
