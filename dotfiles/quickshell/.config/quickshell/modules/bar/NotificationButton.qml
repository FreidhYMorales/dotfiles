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
        color:        hov.hovered ? root.colors.m3tertiaryContainer : root.colors.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Text {
        anchors.centerIn: parent
        text:           Visibilities.silentMode ? "󰂛" : NotifStore.unread > 0 ? "󰂚" : "󰂜"
        color:          hov.hovered ? root.colors.m3onTertiaryContainer : root.colors.m3onSurface
        font.family:    Style.fontFamily
        font.pixelSize: 13
        Behavior on color { CAnim {} }
    }

    // Unread badge
    Rectangle {
        visible: NotifStore.unread > 0
        width:   8
        height:  8
        radius:  Style.cornerRadius
        color:   root.colors.m3tertiary
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
