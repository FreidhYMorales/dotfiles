import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var colors: Colours.palette

    implicitWidth:  clockText.implicitWidth + 20
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Visibilities.calendar || hov.hovered
                   ? root.colors.m3surfaceContainerHighest
                   : root.colors.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.mid(root.colors.m3surfaceContainer, root.colors.m3surfaceContainerHigh)
        Behavior on color { CAnim {} }
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text:           Time.date + "  |  " + Time.timeFull
        color:          root.colors.m3onSurface
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
