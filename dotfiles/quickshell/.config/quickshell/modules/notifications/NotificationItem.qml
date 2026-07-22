import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    property string appName:   ""
    property string summary:   ""
    property string body:      ""
    property string icon:      ""
    property int    urgency:   1
    property int    itemIndex: 0
    property bool   isLast:    false

    implicitHeight: 72

    // Hover background
    Rectangle {
        anchors.fill: parent
        color:        hov.hovered
                          ? Qt.alpha(Colours.m3onSurface, 0.06)
                          : "transparent"
        Behavior on color { CAnim {} }
    }

    // Critical urgency: left accent bar
    Rectangle {
        visible: root.urgency === 2
        width:   3
        anchors {
            left:   parent.left
            top:    parent.top
            bottom: parent.bottom
        }
        color: Colours.m3error
        Behavior on color { CAnim {} }
    }

    // Content row
    Row {
        anchors {
            left:           parent.left
            right:          parent.right
            verticalCenter: parent.verticalCenter
            leftMargin:     root.urgency === 2 ? 15 : 12
            rightMargin:    8
        }
        spacing: 10

        // App icon
        Item {
            width:  24
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                source:       root.icon !== "" ? root.icon : ""
                visible:      root.icon !== ""
                fillMode:     Image.PreserveAspectFit
            }

            Text {
                anchors.centerIn: parent
                visible:          root.icon === ""
                text:             "󰇮"
                font.family:      Style.fontFamily
                font.pixelSize:   18
                color:            Colours.m3onSurfaceVariant
                Behavior on color { CAnim {} }
            }
        }

        // Text column
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 24 - 10 - 28 - 10
            spacing: 2

            Text {
                width:          parent.width
                text:           root.appName
                font.family:    Style.fontFamily
                font.pixelSize: 9
                color:          Colours.m3onSurfaceVariant
                elide:          Text.ElideRight
                Behavior on color { CAnim {} }
            }

            Text {
                width:          parent.width
                text:           root.summary
                font.family:    Style.fontFamily
                font.pixelSize: 12
                font.weight:    Font.Medium
                color:          Colours.m3onSurface
                elide:          Text.ElideRight
                Behavior on color { CAnim {} }
            }

            Text {
                width:            parent.width
                text:             root.body
                font.family:      Style.fontFamily
                font.pixelSize:   11
                color:            Colours.m3onSurfaceVariant
                elide:            Text.ElideRight
                wrapMode:         Text.WordWrap
                maximumLineCount: 2
                Behavior on color { CAnim {} }
            }
        }

        // Dismiss button
        Item {
            width:  28
            height: 28
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius:       7
                color:        dismissHov.hovered
                                  ? Qt.alpha(Colours.m3onSurface, 0.1)
                                  : "transparent"
                Behavior on color { CAnim {} }
            }

            Text {
                anchors.centerIn: parent
                text:           "󰅖"
                font.family:    Style.fontFamily
                font.pixelSize: 14
                color:          Colours.m3onSurfaceVariant
                Behavior on color { CAnim {} }
            }

            HoverHandler { id: dismissHov }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    NotifStore.dismiss(root.itemIndex)
            }
        }
    }

    // Bottom divider (hidden on last item)
    Rectangle {
        visible: !root.isLast
        anchors {
            bottom: parent.bottom
            left:   parent.left
            right:  parent.right
            leftMargin:  12
            rightMargin: 12
        }
        height: 1
        color:  Qt.alpha(Colours.m3outlineVariant, 0.25)
        Behavior on color { CAnim {} }
    }

    HoverHandler { id: hov }
}
