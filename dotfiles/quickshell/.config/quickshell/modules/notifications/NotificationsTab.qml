pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../../services"
import "../../components"

Item {
    id: root

    // Empty state
    Item {
        anchors.fill: parent
        visible:      Notifs.list.length === 0

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "󰂜"
                font.family:    Style.fontFamily
                font.pixelSize: 36
                color:          Colours.m3onSurfaceVariant
                Behavior on color { CAnim {} }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "No notifications"
                font.family:    Style.fontFamily
                font.pixelSize: 12
                color:          Colours.m3onSurfaceVariant
                Behavior on color { CAnim {} }
            }
        }
    }

    // List state
    Item {
        anchors.fill: parent
        visible:      Notifs.list.length > 0

        // Clear all button
        Text {
            id:     clearBtn
            anchors {
                top:   parent.top
                right: parent.right
                topMargin:   8
                rightMargin: 12
            }
            text:           "Clear all"
            font.family:    Style.fontFamily
            font.pixelSize: 10
            color:          clearHov.hovered
                                ? Colours.m3onSurface
                                : Colours.m3onSurfaceVariant
            Behavior on color { CAnim {} }

            HoverHandler { id: clearHov }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    Notifs.dismissAll()
            }
        }

        ScrollView {
            anchors {
                top:         clearBtn.bottom
                bottom:      parent.bottom
                left:        parent.left
                right:       parent.right
                topMargin:   4
                leftMargin:  8
                rightMargin: 8
            }
            clip:         true
            contentWidth: availableWidth

            ListView {
                id:      notifList
                width:   parent.width
                model:   Notifs.list
                spacing: 0
                clip:    true

                delegate: NotificationItem {
                    required property var modelData
                    required property int index

                    width:    notifList.width
                    appName:  modelData.appName
                    summary:  modelData.summary
                    body:     modelData.body
                    icon:     modelData.appIcon
                    urgency:  modelData.urgency
                    notifRef: modelData
                    isLast:   index === notifList.count - 1
                }
            }
        }
    }
}
