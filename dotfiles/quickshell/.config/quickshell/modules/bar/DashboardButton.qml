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
        color:        hov.hovered ? Colours.m3secondaryContainer : Colours.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Text {
        anchors.centerIn: parent
        text:           "󰕮"
        color:          hov.hovered ? Colours.m3onSecondaryContainer : Colours.m3onSurface
        font.family:    "Iosevka Term Nerd Font"
        font.pixelSize: 13
        Behavior on color { CAnim {} }
    }

    HoverHandler { id: hov }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    Visibilities.toggle("dashboard")
    }
}
