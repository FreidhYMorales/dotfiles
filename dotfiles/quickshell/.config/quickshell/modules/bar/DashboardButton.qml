import QtQuick
import "../../services"
import "../../components"

Item {
    id: root
    implicitWidth:  26
    implicitHeight: 26

    property bool standalone: true
    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var  colors:     Colours.palette

    Rectangle {
        anchors.fill: parent
        visible:      root.standalone
        radius:       Style.cornerRadius
        color:        hov.hovered ? root.colors.m3secondaryContainer : root.colors.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Text {
        anchors.centerIn: parent
        text:           "󰕮"
        color:          hov.hovered ? root.colors.m3primary : root.colors.m3onSurface
        font.family:    Style.fontFamily
        font.pixelSize: 13
        scale: hov.hovered ? 1.35 : 1.0
        transformOrigin: Item.Center
        Behavior on color { CAnim {} }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    HoverHandler { id: hov }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    Visibilities.toggle("dashboard")
    }
}
