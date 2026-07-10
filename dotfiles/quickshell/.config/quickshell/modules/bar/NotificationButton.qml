import QtQuick
import "../../services"
import "../../components"

Item {
    id: root
    implicitWidth:  26
    implicitHeight: 26

    property bool standalone: true

    Rectangle {
        anchors.fill: parent
        visible:      root.standalone
        radius:       height / 2
        color:        hov.hovered ? Colours.m3tertiaryContainer : Colours.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Text {
        anchors.centerIn: parent
        text:           Visibilities.silentMode ? "󰂛" : NotifStore.unread > 0 ? "󰂚" : "󰂜"
        color:          hov.hovered ? Colours.m3onTertiaryContainer : Colours.m3onSurface
        font.family:    "Iosevka Term Nerd Font"
        font.pixelSize: 13
        Behavior on color { CAnim {} }
    }

    // Unread badge
    Rectangle {
        visible: NotifStore.unread > 0
        width:   8
        height:  8
        radius:  4
        color:   Colours.m3tertiary
        Behavior on color { CAnim {} }

        anchors {
            top:   parent.top
            right: parent.right
        }
    }

    HoverHandler { id: hov }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    Visibilities.toggle("notifications")
    }
}
