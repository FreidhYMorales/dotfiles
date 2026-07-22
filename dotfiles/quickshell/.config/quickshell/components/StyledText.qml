pragma ComponentBehavior: Bound
import QtQuick
import "../services"

// Styled text with themed font. animate property crossfades text changes.
Text {
    id: root

    property bool animate: false
    // fontStyle accepts a font object from Tokens.font.*.builders.*.build()
    property var  fontStyle

    font.family:    Style.fontFamily
    font.pixelSize: 14
    color:          Colours.m3onSurface
    renderType:     Text.NativeRendering
    textFormat:     Text.PlainText

    onFontStyleChanged: {
        if (fontStyle) {
            font.family    = fontStyle.family    || font.family
            font.pixelSize = fontStyle.pixelSize || font.pixelSize
            font.weight    = fontStyle.weight    || font.weight
        }
    }

    Behavior on color {
        CAnim {}
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            NumberAnimation {
                target:   root
                property: "opacity"
                to:       0
                duration: 100
                easing.type: Easing.InCubic
            }
            PropertyAction {}
            NumberAnimation {
                target:   root
                property: "opacity"
                to:       1
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }
}
