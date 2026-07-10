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
        text:           !Network.connected   ? "󰤭" :
                        Network.signal > 75  ? "󰤨" :
                        Network.signal > 50  ? "󰤥" :
                        Network.signal > 25  ? "󰤢" : "󰤟"
        color:          !Network.connected ? root.colors.m3onSurfaceVariant : root.colors.m3onSurface
        font.family:    "Iosevka Term Nerd Font"
        font.pixelSize: 13
        Behavior on color { CAnim {} }
    }

    Process {
        id: wifiProc
        running: false
        command: ["kitty", "--class", "qs-wifi", "-e", "impala"]
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (wifiProc.running) wifiProc.running = false
            else wifiProc.running = true
        }
    }
}
