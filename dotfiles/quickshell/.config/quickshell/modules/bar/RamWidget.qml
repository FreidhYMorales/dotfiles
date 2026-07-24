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

    HoverHandler { id: hov }

    readonly property bool active: hov.hovered

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

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           "󰍛"
            color:          SysInfo.ram > 85 ? root.colors.m3error : (root.active ? root.colors.m3primary : root.colors.m3onSurface)
            font.family:    Style.fontFamily
            font.pixelSize: 13
            scale: root.active ? 1.35 : 1.0
            transformOrigin: Item.Center
            Behavior on color { CAnim {} }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           SysInfo.ram + "%"
            color:          SysInfo.ram > 85 ? root.colors.m3error : (root.active ? root.colors.m3primary : root.colors.m3onSurface)
            font.family:    Style.fontFamily
            font.pixelSize: 12
            scale: root.active ? 1.35 : 1.0
            transformOrigin: Item.Center
            Behavior on color { CAnim {} }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
    }
}
