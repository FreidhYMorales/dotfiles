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

    HoverHandler { id: hov }

    readonly property bool active: hov.hovered

    Rectangle {
        anchors.fill: parent
        visible:      root.standalone
        radius:       Style.cornerRadius
        color:        root.colors.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Text {
        anchors.centerIn: parent
        text:           !Bluetooth.powered   ? "󰂲" :
                        !Bluetooth.connected ? "󰂯" : "󰂱"
        color:          root.active ? root.colors.m3primary :
                        !Bluetooth.powered   ? root.colors.m3onSurfaceVariant :
                        !Bluetooth.connected ? root.colors.m3onSurface : root.colors.m3primary
        font.family:    Style.fontFamily
        font.pixelSize: 13
        scale: root.active ? 1.35 : 1.0
        transformOrigin: Item.Center
        Behavior on color { CAnim {} }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Process {
        id: btProc
        running: false
        command: ["kitty", "--class", "qs-bluetooth", "-e", "bluetui"]
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (btProc.running) btProc.running = false
            else btProc.running = true
        }
    }
}
