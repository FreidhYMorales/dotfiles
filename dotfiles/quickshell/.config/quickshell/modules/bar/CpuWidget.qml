import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var colors: Colours.palette

    implicitWidth:  row.implicitWidth + 16
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
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
            text:           "󰻠"
            color:          SysInfo.cpu > 80 ? root.colors.m3error : root.colors.m3onSurface
            font.family:    Style.fontFamily
            font.pixelSize: 13
            Behavior on color { CAnim {} }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           SysInfo.cpu + "%"
            color:          SysInfo.cpu > 80 ? root.colors.m3error : root.colors.m3onSurface
            font.family:    Style.fontFamily
            font.pixelSize: 12
            Behavior on color { CAnim {} }
        }
    }
}
