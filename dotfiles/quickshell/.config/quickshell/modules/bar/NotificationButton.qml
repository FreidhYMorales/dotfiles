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
        color:        stateLayer.hovered ? root.colors.m3tertiaryContainer : root.colors.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    HoverIconText {
        anchors.centerIn: parent
        text:           Visibilities.silentMode ? "󰂛" : Notifs.list.length > 0 ? "󰂚" : "󰂜"
        color:          stateLayer.hovered ? root.colors.m3primary : root.colors.m3onSurface
        font.pixelSize: 13
        active:         stateLayer.hovered
    }

    // Unread badge
    Rectangle {
        visible: Notifs.list.length > 0
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

    // El fondo ya cambia de color sólido en hover (swap, no tinte translúcido)
    // — tinte propio del StateLayer apagado para no sumarle un segundo efecto.
    StateLayer {
        id: stateLayer
        hoverOpacity:   0
        pressedOpacity: 0
        cursorShape:    Qt.PointingHandCursor
        onClicked:      Visibilities.toggle("notifications")
    }
}
