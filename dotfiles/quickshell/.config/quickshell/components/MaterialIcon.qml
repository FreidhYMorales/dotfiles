pragma ComponentBehavior: Bound
import QtQuick

// Material Symbols icon rendered as text glyph.
// fontStyle accepts a builder result: Tokens.font.icon.builders.medium.build()
Text {
    id: root

    property bool animate: false
    property var  fontStyle

    font.family:    "Material Symbols Rounded"
    font.pixelSize: 20
    color:          "#cdd6f4"
    renderType:     Text.NativeRendering

    onFontStyleChanged: {
        if (fontStyle) {
            if (fontStyle.pixelSize) font.pixelSize = fontStyle.pixelSize
            if (fontStyle.weight)    font.weight    = fontStyle.weight
        }
    }

    Behavior on color {
        enabled: root.animate
        ColorAnimation { duration: 150 }
    }
}
