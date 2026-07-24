import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var colors: Colours.palette

    implicitWidth:  clockText.implicitWidth + 30
    implicitHeight: 26

    readonly property bool active: hov.hovered || Visibilities.calendar

    Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
        color: "transparent"
        border.width: 2
        antialiasing:  false
        border.color: Colours.mid(root.colors.m3surfaceContainer, root.colors.m3surfaceContainerHigh)
        Behavior on color { CAnim {} }
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text:           Time.date + "  |  " + Time.time24
        color:          root.active ? root.colors.m3primary : root.colors.m3onSurface
        font.family:    Style.fontFamily
        font.pixelSize: 12
        font.weight:    Font.Medium
        scale: root.active ? 1.08 : 1.0
        transformOrigin: Item.Center
        Behavior on color { CAnim {} }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }

    MouseArea {
        anchors.fill: parent
        onClicked:    Visibilities.toggle("calendar")
    }
}
