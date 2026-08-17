import QtQuick
import "../../services"
import "../../components"

// Left click starts/stops a recording — the only control this widget has.
// Mode (screen/region/window) and the audio toggle live in the dashboard's
// RecorderSection now; this just calls Recorder.start()/stop() against
// whatever mode was picked there.
Item {
    id: root

    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var colors: Colours.palette

    implicitWidth:  row.implicitWidth + 16
    implicitHeight: 26

    HoverHandler { id: hov }

    readonly property bool active: hov.hovered

    function _fmtElapsed() {
        const m = Math.floor(Recorder.elapsedSeconds / 60)
        const s = Recorder.elapsedSeconds % 60
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
        color: "transparent"
        Behavior on color { CAnim {} }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        HoverIconText {
            anchors.verticalCenter: parent.verticalCenter
            text:           "󰻃"
            color:          Recorder.recording ? root.colors.m3error : (root.active ? root.colors.m3primary : root.colors.m3onSurface)
            font.pixelSize: 13
            active:         root.active
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible:        Recorder.recording
            text:           root._fmtElapsed()
            color:          root.colors.m3error
            font.family:    Style.fontFamily
            font.pixelSize: 12
            Behavior on color { CAnim {} }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Recorder.recording ? Recorder.stop() : Recorder.start()
    }
}
