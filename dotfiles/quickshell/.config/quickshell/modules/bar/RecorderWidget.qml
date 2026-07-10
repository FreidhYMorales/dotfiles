import QtQuick
import "../../services"
import "../../components"

// Left click always starts/stops a full-screen recording (quick access).
// Right click opens RecorderModeOsd to pick screen/region/window — but only
// while idle; while recording, stopping goes through the left click only,
// a single path instead of two ways to stop.
Item {
    id: root

    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var colors: Colours.palette

    implicitWidth:  row.implicitWidth + 16
    implicitHeight: 26

    function _fmtElapsed() {
        const m = Math.floor(Recorder.elapsedSeconds / 60)
        const s = Recorder.elapsedSeconds % 60
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color:        root.colors.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.mid(root.colors.m3surfaceContainer, root.colors.m3surfaceContainerHigh)
        Behavior on color { CAnim {} }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           "󰻃"
            color:          Recorder.recording ? root.colors.m3error : root.colors.m3onSurface
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 13
            Behavior on color { CAnim {} }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible:        Recorder.recording
            text:           root._fmtElapsed()
            color:          root.colors.m3error
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 12
            Behavior on color { CAnim {} }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (Recorder.recording) Recorder.stop()
                else                    Recorder.startScreen()
            } else if (mouse.button === Qt.RightButton && !Recorder.recording) {
                Visibilities.recorderOsdCenterX = root.mapToItem(null, root.width / 2, 0).x
                Visibilities.toggle("recorderModeOsd")
            }
        }
    }
}
