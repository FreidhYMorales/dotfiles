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
            if (wifiProc.running) wifiProc.running = false
            else wifiProc.running = true
        }
    }

    HoverIconText {
        anchors.centerIn: parent
        text:           !Network.connected   ? "󰤭" :
                        Network.signal > 75  ? "󰤨" :
                        Network.signal > 50  ? "󰤥" :
                        Network.signal > 25  ? "󰤢" : "󰤟"
        color:          root.active ? root.colors.m3primary : (!Network.connected ? root.colors.m3onSurfaceVariant : root.colors.m3onSurface)
        font.pixelSize: 13
        active:         root.active
    }

    Process {
        id: wifiProc
        running: false
        command: ["kitty", "--class", "qs-wifi", "-e", "impala"]
    }
}
