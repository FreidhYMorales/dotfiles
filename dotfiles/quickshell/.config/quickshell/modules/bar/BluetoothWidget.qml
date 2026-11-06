import QtQuick
import Quickshell.Io
import "../../services"
import "../../components"

Item {
    id: root
    implicitWidth:  26 + (standalone ? 16 : 0)
    implicitHeight: 26

    property bool standalone: true
    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var  colors:     Colours.palette

    readonly property bool active: stateLayer.hovered

    Rectangle {
        anchors.fill: parent
        visible:      root.standalone
        radius:       Style.cornerRadius
        color:        root.colors.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    // El fondo de este widget es un color fijo (no reacciona al hover), solo
    // el ícono cambia de color — tinte del StateLayer apagado a propósito.
    StateLayer {
        id: stateLayer
        hoverOpacity:   0
        pressedOpacity: 0
        onClicked: {
            if (btProc.running) btProc.running = false
            else btProc.running = true
        }
    }

    HoverIconText {
        anchors.centerIn: parent
        text:           !Bluetooth.powered   ? "󰂲" :
                        !Bluetooth.connected ? "󰂯" : "󰂱"
        color:          root.active ? root.colors.m3primary :
                        !Bluetooth.powered   ? root.colors.m3onSurfaceVariant :
                        !Bluetooth.connected ? root.colors.m3onSurface : root.colors.m3primary
        font.pixelSize: 13
        active:         root.active
    }

    Process {
        id: btProc
        running: false
        command: ["kitty", "--class", "qs-bluetooth", "-e", "bluetui"]
    }
}
