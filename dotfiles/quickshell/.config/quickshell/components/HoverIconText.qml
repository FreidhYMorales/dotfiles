import QtQuick
import "../services"

// Icon/label glyph for bar widgets — hover-driven scale-up + color
// transition. Callers still own `text`/`color`/`font.pixelSize` (and
// whatever drives them: thresholds, hover state, etc.) — this only
// centralizes the scale choreography that was identical, verbatim, across
// ~14 Text elements in modules/bar/*.qml. `scaleFactor` defaults to the
// icon-glyph value (1.35); ClockWidget's full date/time label overrides it
// to a smaller 1.08 — scaling a whole string 1.35x reads as broken, unlike
// a single glyph.
Text {
    id: root

    property bool active: false
    property real scaleFactor: 1.35

    font.family: Style.fontFamily
    scale: root.active ? root.scaleFactor : 1.0
    transformOrigin: Item.Center

    Behavior on color { CAnim {} }
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
}
