import QtQuick
import "../../services"
import "../../components"

Item {
    implicitWidth:  clockText.implicitWidth + 20
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Visibilities.calendar || hov.hovered
                   ? Colours.m3surfaceContainerHighest
                   : Colours.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.mid(Colours.m3surfaceContainer, Colours.m3surfaceContainerHigh)
        Behavior on color { CAnim {} }
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text:           Time.date + "  |  " + Time.timeFull
        color:          Colours.m3onSurface
        font.family:    "Iosevka Term Nerd Font"
        font.pixelSize: 12
        font.weight:    Font.Medium
        Behavior on color { CAnim {} }
    }

    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }

    MouseArea {
        anchors.fill: parent
        onClicked:    Visibilities.toggle("calendar")
    }
}
