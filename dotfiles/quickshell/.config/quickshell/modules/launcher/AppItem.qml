import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    property string appName:        ""
    property string appExec:        ""
    property string appIcon:        ""
    property string appDescription: ""
    property bool   showDivider:    true
    property bool   isSelected:     false

    signal clicked()
    signal hovered()

    implicitHeight: 64

    // Background
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.isSelected
               ? Qt.alpha(Colours.m3primaryContainer, 0.45)
               : hov.hovered
                 ? Qt.alpha(Colours.m3onSurface, 0.07)
                 : "transparent"
        Behavior on color { CAnim {} }
    }

    // Left selection accent
    Rectangle {
        anchors {
            left:           parent.left
            leftMargin:     4
            verticalCenter: parent.verticalCenter
        }
        width:   3
        height:  28
        radius:  2
        visible: root.isSelected
        color:   Colours.m3primary
        Behavior on color { CAnim {} }
    }

    // Icon container (rounded square)
    Item {
        id: iconArea
        width: 36; height: 36
        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }

        Rectangle {
            anchors.fill: parent
            radius:       12
            color:        root.isSelected
                          ? Colours.m3primary
                          : Colours.m3primaryContainer
            Behavior on color { CAnim {} }
        }

        Image {
            id: iconImg
            anchors { fill: parent; margins: 5 }
            source:   root.appIcon ? ("file://" + root.appIcon) : ""
            fillMode: Image.PreserveAspectFit
            smooth:   true
            mipmap:   true
            visible:  status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible:        !iconImg.visible
            text:           root.appName.charAt(0).toUpperCase()
            color:          root.isSelected ? Colours.m3onPrimary : Colours.m3onPrimaryContainer
            font.family:    Style.fontFamily
            font.pixelSize: 15
            font.weight:    Font.Medium
            Behavior on color { CAnim {} }
        }
    }

    // Name + description
    Column {
        anchors {
            left:           iconArea.right
            right:          parent.right
            verticalCenter: parent.verticalCenter
            leftMargin:     12
            rightMargin:    14
        }
        spacing: 3

        Text {
            width:          parent.width
            text:           root.appName
            color:          root.isSelected ? Colours.m3primary : Colours.m3onSurface
            font.family:    Style.fontFamily
            font.pixelSize: 15
            font.weight:    Font.Medium
            elide:          Text.ElideRight
            Behavior on color { CAnim {} }
        }

        Text {
            width:          parent.width
            text:           root.appDescription
            visible:        root.appDescription.length > 0
            color:          Qt.alpha(Colours.m3onSurfaceVariant, 0.75)
            font.family:    Style.fontFamily
            font.pixelSize: 11
            elide:          Text.ElideRight
            Behavior on color { CAnim {} }
        }
    }

    // Divider
    Rectangle {
        anchors {
            bottom:      parent.bottom
            left:        parent.left
            right:       parent.right
            leftMargin:  14
            rightMargin: 14
        }
        height:  1
        visible: root.showDivider
        color:   Qt.alpha(Colours.m3outlineVariant, 0.35)
        Behavior on color { CAnim {} }
    }

    HoverHandler {
        id: hov
        onHoveredChanged: if (hovered) root.hovered()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.clicked()
    }
}
