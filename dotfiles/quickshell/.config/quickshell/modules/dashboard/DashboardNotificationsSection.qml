import QtQuick
import "../../services"
import "../../components"
import "../notifications"

Item {
    id: root

    implicitHeight: 324
    implicitWidth:  parent?.width ?? 300

    property int activeTab: 0

    // Tab bar
    Item {
        id:     tabBar
        width:  parent.width
        height: 44

        Row {
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: [
                    { icon: "󰂚", label: "Notifications" },
                    { icon: "󰃭", label: "Calendar"      },
                    { icon: "󰖙", label: "Weather"       }
                ]

                delegate: Item {
                    id: tabDelegate
                    required property var modelData
                    required property int index

                    readonly property bool active: root.activeTab === index

                    implicitHeight: 28
                    implicitWidth:  tabRow.implicitWidth + 24

                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color:  tabDelegate.active ? Colours.m3primaryContainer : "transparent"
                        Behavior on color { CAnim {} }
                    }

                    Row {
                        id:      tabRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           tabDelegate.modelData.icon
                            font.family:    "Iosevka Term Nerd Font"
                            font.pixelSize: 12
                            color:          tabDelegate.active ? Colours.m3onPrimaryContainer : Colours.m3onSurfaceVariant
                            Behavior on color { CAnim {} }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           tabDelegate.modelData.label
                            font.family:    "Iosevka Term Nerd Font"
                            font.pixelSize: 11
                            color:          tabDelegate.active ? Colours.m3onPrimaryContainer : Colours.m3onSurfaceVariant
                            Behavior on color { CAnim {} }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.activeTab = tabDelegate.index
                    }
                }
            }
        }

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color:  Qt.alpha(Colours.m3outlineVariant, 0.3)
            Behavior on color { CAnim {} }
        }
    }

    // Content area — fills space below tab bar
    Item {
        anchors {
            top:    tabBar.bottom
            bottom: parent.bottom
            left:   parent.left
            right:  parent.right
        }

        NotificationsTab {
            anchors.fill: parent
            visible:      root.activeTab === 0
        }

        CalendarTab {
            anchors.fill: parent
            visible:      root.activeTab === 1
        }

        WeatherTab {
            anchors.fill: parent
            visible:      root.activeTab === 2
        }
    }
}
