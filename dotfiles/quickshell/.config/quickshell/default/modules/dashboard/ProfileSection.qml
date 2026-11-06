import Quickshell
import QtQuick
import "../../services"
import "../../components"
import "../../utils" as Utils

Item {
    id: root

    implicitHeight: rightCol.implicitHeight + 10
    implicitWidth:  parent?.width ?? 300

    property string _user:   Quickshell.env("USER")

    // Avatar (left, vertically centered to the whole capsule)
    Rectangle {
        id:     avatar
        width:  56
        height: 56
        radius: Style.cornerRadius
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
            font.family:    Style.fontFamily
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
            font.family:    Style.fontFamily
            font.pixelSize: 16
            font.weight:    Font.Medium
            elide:          Text.ElideRight
            width:          parent.width
            Behavior on color { CAnim {} }
        }

        Text {
            text:           Utils.OsInfo.uptime.length > 0 ? "up " + Utils.OsInfo.uptime : "up —"
            color:          Colours.m3onSurfaceVariant
            font.family:    Style.fontFamily
            font.pixelSize: 11
            Behavior on color { CAnim {} }
        }

        // Power button row — flush against the panel, no nested pill (the
        // panel itself already carries a 2px border; a bordered pill inside
        // it double-framed the same edge). Separated from name/uptime by a
        // plain divider, same convention as the rest of the dashboard.
        Item {
            height: 28
            width:  parent.width

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 1
                color:  Qt.alpha(Colours.m3outlineVariant, 0.25)
                Behavior on color { CAnim {} }
            }

            Row {
                id: powerRow
                anchors {
                    left:           parent.left
                    right:          parent.right
                    verticalCenter: parent.verticalCenter
                }
                spacing: Math.max(0, (width - 5 * 24) / 4)

                Repeater {
                    model: PowerActions.actions

                    delegate: Item {
                        id: powerBtn
                        required property var modelData

                        width:  24
                        height: 24
                        anchors.verticalCenter: parent?.verticalCenter

                        HoverIconText {
                            anchors.centerIn: parent
                            text:           powerBtn.modelData.icon
                            color:          btnHov.hovered ? Colours.m3primary : Colours.m3onSurfaceVariant
                            font.pixelSize: 13
                            active:         btnHov.hovered
                        }

                        HoverHandler { id: btnHov }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                if (powerBtn.modelData.action) powerBtn.modelData.action()
                                else Quickshell.execDetached(powerBtn.modelData.cmd)
                                Visibilities.toggle("dashboard")
                            }
                        }
                    }
                }
            }
        }
    }
}
