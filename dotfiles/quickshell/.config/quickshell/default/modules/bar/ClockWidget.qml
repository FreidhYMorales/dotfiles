import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    // Per-monitor palette (bar/panels only — see Colours.paletteFor).
    // Defaults to the shared global palette so this widget still works
    // wherever else it might be instantiated without a screen context.
    property var colors: Colours.palette

    // Overridable size (defaults match the old bar's scale) — N-C renders
    // this notably bigger to match the visual weight of TL's workspace
    // circles, without changing the bar's own look if it comes back.
    property int fontPixelSize: 12
    property int widgetHeight:  26

    implicitWidth:  clockText.implicitWidth + 30
    implicitHeight: root.widgetHeight

    readonly property bool active: stateLayer.hovered || Visibilities.calendar

    // Border removed (project-wide "fill color only, no colored border"
    // simplification already applied to the notch's other zones) — this
    // Rectangle used to be a transparent-fill border-only outline.

    // No fondo/tinte propio en este widget (solo el borde de arriba y el
    // color del texto reaccionan al hover) — tinte apagado a propósito para
    // no sumar un efecto visual que no existía antes.
    StateLayer {
        id: stateLayer
        hoverOpacity:   0
        pressedOpacity: 0
        cursorShape:    Qt.PointingHandCursor
        onClicked:      Visibilities.toggle("calendar")
    }

    HoverIconText {
        id: clockText
        anchors.centerIn: parent
        text:           Time.time24
        color:          root.active ? root.colors.m3primary : root.colors.m3onSurface
        font.pixelSize: root.fontPixelSize
        font.weight:    Font.Medium
        active:         root.active
        scaleFactor:    1.08
    }
}
