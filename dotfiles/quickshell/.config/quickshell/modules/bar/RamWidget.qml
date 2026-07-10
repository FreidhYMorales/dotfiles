import QtQuick
import "../../services"
import "../../components"

Item {
    implicitWidth:  row.implicitWidth + 16
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color:        Colours.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.mid(Colours.m3surfaceContainer, Colours.m3surfaceContainerHigh)
        Behavior on color { CAnim {} }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           "󰍛"
            color:          SysInfo.ram > 85 ? Colours.m3error : Colours.m3onSurface
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 13
            Behavior on color { CAnim {} }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:           SysInfo.ram + "%"
            color:          SysInfo.ram > 85 ? Colours.m3error : Colours.m3onSurface
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 12
            Behavior on color { CAnim {} }
        }
    }
}
