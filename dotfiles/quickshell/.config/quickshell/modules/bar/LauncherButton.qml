import QtQuick
import "../../services"
import "../../components"

Item {
    id: root
    property bool standalone: true
    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var  colors:     Colours.palette

    implicitWidth:  26
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        visible:      root.standalone
        radius:       height / 2
        color:        hov.hovered ? root.colors.m3primaryContainer : root.colors.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Text {
        anchors.centerIn: parent
        text:           "󰣇"
        color:          hov.hovered ? root.colors.m3onPrimaryContainer : root.colors.m3onSurface
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
