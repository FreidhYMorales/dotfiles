import QtQuick
import Quickshell.Io
import "../../services"
import "../../components"

Item {
    id: root
    implicitWidth:  26 + (standalone ? 16 : 0)
    implicitHeight: 26

    property bool standalone: true

    Rectangle {
        anchors.fill: parent
        visible:      root.standalone
        radius:       height / 2
        color:        Colours.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Text {
        anchors.centerIn: parent
        text:           !Bluetooth.powered   ? "󰂲" :
                        !Bluetooth.connected ? "󰂯" : "󰂱"
        color:          !Bluetooth.powered   ? Colours.m3onSurfaceVariant :
                        !Bluetooth.connected ? Colours.m3onSurface : Colours.m3primary
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
