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

    Rectangle {
        anchors.fill: parent
        visible:      root.standalone
        radius:       height / 2
        color:        root.colors.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Text {
        anchors.centerIn: parent
        text:           !Bluetooth.powered   ? "󰂲" :
                        !Bluetooth.connected ? "󰂯" : "󰂱"
        color:          !Bluetooth.powered   ? root.colors.m3onSurfaceVariant :
                        !Bluetooth.connected ? root.colors.m3onSurface : root.colors.m3primary
        font.family:    "Iosevka Term Nerd Font"
        font.pixelSize: 13
        Behavior on color { CAnim {} }
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
