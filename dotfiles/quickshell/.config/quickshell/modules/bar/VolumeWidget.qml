import QtQuick
import Quickshell.Io
import "../../services"
import "../../components"

Item {
    id: root
    implicitWidth:  Math.max(26, row.implicitWidth) + (standalone ? 16 : 0)
    implicitHeight: 26

    property bool standalone:   true
    property bool showPercent:  false
    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var  colors:       Colours.palette

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.showPercent = false
    }

    Connections {
        target: Audio
        function onVolumeChanged() { root.showPercent = true; hideTimer.restart() }
        function onMutedChanged()  { root.showPercent = true; hideTimer.restart() }
    }

    function updateCenterX() {
        if (!standalone) return
        Visibilities.volumeBarCenterX = 8 + mapToItem(null, implicitWidth / 2, 0).x
    }
    Component.onCompleted:  Qt.callLater(updateCenterX)
    onXChanged:             Qt.callLater(updateCenterX)
    onImplicitWidthChanged: Qt.callLater(updateCenterX)

    Rectangle {
        anchors.fill: parent
        visible:      root.standalone
        radius:       height / 2
        color:        root.colors.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           Audio.muted       ? "󰖁" :
                            Audio.volume > 66 ? "󰕾" :
                            Audio.volume > 33 ? "󰖀" : "󰕿"
            color:          Audio.muted ? root.colors.m3onSurfaceVariant : root.colors.m3onSurface
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 13
            Behavior on color { CAnim {} }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width:  root.showPercent ? percentText.implicitWidth + 10 : 0
            height: percentText.implicitHeight
            clip:   true
            Behavior on width {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Text {
                id: percentText
                anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
                text:           Audio.volume + "%"
                color:          Audio.muted ? root.colors.m3onSurfaceVariant : root.colors.m3onSurface
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 12
                Behavior on color { CAnim {} }
            }
        }
    }

    // Right click opens a full PipeWire mixer (per-app volumes, sink/source
    // picker) — same "kitty + TUI" pattern as BluetoothWidget/WifiWidget.
    // Left click keeps the quick OSD (Osd.qml) for the common case.
    Process {
        id: mixerProc
        running: false
        command: ["kitty", "--class", "qs-volume", "-e", "wiremix"]
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                Visibilities.toggle("volume")
            } else if (mouse.button === Qt.RightButton) {
                if (mixerProc.running) mixerProc.running = false
                else mixerProc.running = true
            }
        }
    }
}
