import QtQuick
import "../../services"
import "../../components"

// Modeled on AppItem.qml — one launcher command (">wallpaper", ">theme") per
// row, shown when the search field is just ">" or ">partial-name". Unlike
// AppItem's icon (a real app icon file, falling back to a letter), this
// always shows a fixed nerd-font glyph since commands aren't files.
Item {
    id: root

    property string cmdIcon:        ""
    property string cmdName:        ""
    property string cmdDescription: ""
    property bool   showDivider:    true
    property bool   isSelected:     false

    signal clicked()
    signal hovered()

    implicitHeight: 64

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

    Item {
        id: iconArea
        width: 36; height: 36
        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }

        Rectangle {
            anchors.fill: parent
            radius:       height / 2
            color:        root.isSelected
                          ? Colours.m3primary
                          : Colours.m3primaryContainer
            Behavior on color { CAnim {} }
        }

        Text {
            anchors.centerIn: parent
            text:           root.cmdIcon
            color:          root.isSelected ? Colours.m3onPrimary : Colours.m3onPrimaryContainer
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 16
            Behavior on color { CAnim {} }
        }
    }

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
            text:           root.cmdName
            color:          root.isSelected ? Colours.m3primary : Colours.m3onSurface
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 15
            font.weight:    Font.Medium
            elide:          Text.ElideRight
            Behavior on color { CAnim {} }
        }

        Text {
            width:          parent.width
            text:           root.cmdDescription
            visible:        root.cmdDescription.length > 0
            color:          Qt.alpha(Colours.m3onSurfaceVariant, 0.75)
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 11
            elide:          Text.ElideRight
            Behavior on color { CAnim {} }
        }
    }

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
