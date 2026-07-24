pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    property bool open:      false
    property bool panelOpen: false

    Connections {
        target: Visibilities
        function onNotificationsChanged() {
            if (Visibilities.notifications) {
                closeTimer.stop()
                root.open      = true
                root.panelOpen = false
                openTimer.restart()
            } else {
                openTimer.stop()
                root.panelOpen = false
                closeTimer.restart()
            }
        }
    }

    // One frame delay — PanelWindow needs to finish layout before y is reliable
    Timer {
        id:       openTimer
        interval: 16
        onTriggered: root.panelOpen = true
    }

    // Keeps window visible during the close animation (350ms + buffer)
    Timer {
        id:       closeTimer
        interval: 400
        onTriggered: root.open = false
    }

    Rectangle {
        id:            panel
        anchors.right: parent.right
        width:         root.width
        height:        root.height
        y:             root.panelOpen ? 0 : -root.height
        Behavior on y {
            NumberAnimation {
                duration: 350
                easing.type:        Easing.BezierSpline
                easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
            }
        }

        radius: Style.cornerRadius
        color:          Colours.m3surfaceContainer
        border.width: 2
        border.color: Qt.alpha(Colours.m3primary, 0.9)
        clip:           true
        layer.enabled:  true
        Behavior on color { CAnim {} }


        MouseArea { anchors.fill: parent }

        Item {
            id:      header
            width:   parent.width
            height:  44
            opacity: root.panelOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }

            Text {
                anchors {
                    left:           parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin:     16
                }
                text:           "Notifications"
                font.family:    Style.fontFamily
                font.pixelSize: 13
                font.weight:    Font.Medium
                color:          Colours.m3onSurface
                Behavior on color { CAnim {} }
            }

            Row {
                anchors {
                    right:          parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin:    12
                }
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           Visibilities.silentMode ? "󰂛" : "󰂚"
                    font.family:    Style.fontFamily
                    font.pixelSize: 13
                    color:          Visibilities.silentMode
                                        ? Colours.m3onSurfaceVariant
                                        : Colours.m3onSurface
                    Behavior on color { CAnim {} }
                }

                Item {
                    implicitWidth:  38
                    implicitHeight: 22
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: Style.cornerRadius
                        color:        Visibilities.silentMode
                                          ? Colours.m3primary
                                          : Qt.alpha(Colours.m3onSurface, 0.18)
                        Behavior on color { CAnim {} }
                    }

                    Rectangle {
                        id:     thumb
                        width:  18
                        height: 18
                        radius: Style.cornerRadius
                        color:  Visibilities.silentMode
                                    ? Colours.m3onPrimary
                                    : Colours.m3surface
                        anchors.verticalCenter: parent.verticalCenter
                        x:      Visibilities.silentMode ? parent.width - width - 2 : 2
                        Behavior on x     { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { CAnim {} }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    Visibilities.silentMode = !Visibilities.silentMode
                    }
                }
            }

            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height:  1
                color:   Qt.alpha(Colours.m3outlineVariant, 0.3)
                Behavior on color { CAnim {} }
            }
        }

        NotificationsTab {
            anchors {
                top:    header.bottom
                bottom: parent.bottom
                left:   parent.left
                right:  parent.right
            }
            opacity: root.panelOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
        }
    }
}
