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
        text:           !Network.connected   ? "󰤭" :
                        Network.signal > 75  ? "󰤨" :
                        Network.signal > 50  ? "󰤥" :
                        Network.signal > 25  ? "󰤢" : "󰤟"
        color:          !Network.connected ? Colours.m3onSurfaceVariant : Colours.m3onSurface
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
