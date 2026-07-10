import QtQuick
import "../../services"
import "../../components"

Item {
    id: root
    property bool standalone: true

    implicitWidth:  26
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        visible:      root.standalone
        radius:       height / 2
        color:        hov.hovered ? Colours.m3primaryContainer : Colours.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Text {
        anchors.centerIn: parent
        text:           "󰣇"
        color:          hov.hovered ? Colours.m3onPrimaryContainer : Colours.m3onSurface
        font.family:    "Iosevka Term Nerd Font"
        font.pixelSize: 14
        Behavior on color { CAnim {} }
    }

    HoverHandler { id: hov }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    Visibilities.toggle("launcher")
    }
}
