pragma ComponentBehavior: Bound

import QtQuick
import "../../services"

// Generalized slider, extracted from the volume/brightness sliders
// duplicated inline in modules/bar/Osd.qml (~lines 165-253 volume,
// ~316-382 brightness) — same 3-layer visual (track, animated fill,
// animated thumb) and mouseX/travel math, generalized with min/max/step
// instead of a fixed 0-100 range. Osd.qml's own two copies are left
// untouched — this doesn't replace them, it's for new callers only
// (ScreensaverForm.qml).
//
// Unlike a bindable QML property, `value` is NOT written back by this
// component — same contract as Osd.qml's sliders (`Audio.setVolume(pct)`
// is called instead of binding `value` both ways). The parent owns the
// source of truth and updates `value` itself from `onMoved`.
Item {
    id: root

    property real value: 0
    property real min:   0
    property real max:   100
    property real step:  1
    property color trackColor: Colours.m3surfaceContainerHighest
    property color fillColor:  Colours.m3primary
    property color thumbColor: Colours.m3onPrimary
    // Optional glyph centered in the thumb (e.g. an icon), matching how
    // Osd.qml puts the volume/brightness icon inside the thumb itself.
    property string icon: ""
    property bool   enabled: true

    signal moved(real value)

    implicitHeight: 28

    readonly property real thumbDia: height
    readonly property real travel:   Math.max(0, width - thumbDia)
    readonly property real thumbX: root.travel > 0
        ? Math.max(0, Math.min(root.travel, ((root.value - root.min) / (root.max - root.min)) * root.travel))
        : 0

    opacity: root.enabled ? 1.0 : 0.38
    Behavior on opacity { NumberAnimation { duration: 120 } }

    // Track
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color:  root.trackColor
        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.InOutCubic } }
    }

    // Fill
    Rectangle {
        width:  root.thumbX + root.thumbDia
        height: parent.height
        radius: height / 2
        color:  root.fillColor
        Behavior on width { NumberAnimation { duration: 80 } }
        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.InOutCubic } }
    }

    // Thumb
    Rectangle {
        id: thumb
        x:      root.thumbX
        width:  root.thumbDia
        height: root.thumbDia
        radius: height / 2
        color:  root.thumbColor
        Behavior on x     { NumberAnimation { duration: 80 } }
        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.InOutCubic } }

        Text {
            anchors.centerIn: parent
            visible:        root.icon !== ""
            text:           root.icon
            color:          root.fillColor
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 13
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled:      root.enabled
        cursorShape:  Qt.SizeHorCursor

        function setFromX(mx) {
            if (root.travel <= 0) return
            const pct     = Math.max(0, Math.min(1, mx / root.travel))
            const raw     = root.min + pct * (root.max - root.min)
            const stepped = Math.round(raw / root.step) * root.step
            root.moved(Math.max(root.min, Math.min(root.max, stepped)))
        }

        onPressed:         setFromX(mouseX)
        onPositionChanged: if (pressed) setFromX(mouseX)
    }
}
