pragma ComponentBehavior: Bound
import QtQuick
import "../../services"

// Icon button stub matching Caelestia's IconButton API used in the lock screen.
Item {
    id: root

    // Button type enum — Tonal is the secondary-container variant
    enum ButtonType { Filled = 0, Tonal = 1, Outlined = 2, Standard = 3 }

    property int    type:       IconButton.ButtonType.Filled
    property string icon:       ""
    property color  iconColor:  Colours.m3onSurface
    property bool   isRound:    false
    property bool   shapeMorph: false
    property bool   disabled:   false
    property bool   checked:    false
    property var    fontStyle

    signal clicked()

    implicitWidth:  36
    implicitHeight: 36

    opacity: disabled ? 0.38 : 1.0

    Rectangle {
        anchors.fill: parent
        radius:       root.isRound ? Math.min(width, height) / 2 : 8
        color:        root.checked   ? Colours.m3primary
                    : root.type === IconButton.ButtonType.Tonal ? Colours.m3surfaceContainerHigh
                    : Colours.m3primary
        opacity:      0.9
    }

    Text {
        anchors.centerIn: parent
        text:           root.icon
        font.family:    "Material Symbols Rounded"
        font.pixelSize: 18
        color:          root.iconColor
    }

    MouseArea {
        anchors.fill:  parent
        enabled:       !root.disabled
        cursorShape:   Qt.PointingHandCursor
        onClicked:     root.clicked()
    }
}
