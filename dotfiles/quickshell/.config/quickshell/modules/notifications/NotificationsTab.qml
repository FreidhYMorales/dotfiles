import QtQuick
import QtQuick.Controls
import "../../services"
import "../../components"

Item {
    id: root

    // Empty state
    Item {
        anchors.fill: parent
        visible:      NotifStore.notifications.count === 0

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "󰂜"
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 36
                color:          Colours.m3onSurfaceVariant
                Behavior on color { CAnim {} }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           "No notifications"
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 12
                color:          Colours.m3onSurfaceVariant
                Behavior on color { CAnim {} }
            }
        }
    }

    // List state
    Item {
        anchors.fill: parent
        visible:      NotifStore.notifications.count > 0

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
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 10
            color:          clearHov.hovered
                                ? Colours.m3onSurface
                                : Colours.m3onSurfaceVariant
            Behavior on color { CAnim {} }

            HoverHandler { id: clearHov }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    NotifStore.clear()
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
                model:   NotifStore.notifications
                spacing: 0
                clip:    true

                delegate: NotificationItem {
                    width:    notifList.width
                    appName:  model.app
                    summary:  model.summary
                    body:     model.body
                    icon:     model.icon
                    urgency:  model.urgency
                    itemIndex: index
                    isLast:   index === notifList.count - 1
                }
            }
        }
    }
}
