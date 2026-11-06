pragma ComponentBehavior: Bound
import QtQuick

// Material Design state layer (hover/press tint overlay).
Rectangle {
    id: root

    property color  tintColor:       "#ffffff"
    property real   hoverOpacity:    0.08
    property real   pressedOpacity:  0.12
    property bool   hoverEnabled:    true
    property int    cursorShape:     Qt.ArrowCursor
    property int    acceptedButtons: Qt.LeftButton

    // Exposed so a parent can drive other visual effects (icon/text color,
    // scale, etc.) off the same hover/press state instead of keeping a
    // separate HoverHandler around just to read .hovered.
    readonly property alias hovered: ma.containsMouse
    readonly property alias pressed: ma.pressed

    signal clicked()
    // Only fires when acceptedButtons includes Qt.RightButton — left click
    // (or any other accepted button) always goes through clicked() above,
    // same as before this existed.
    signal rightClicked()

    anchors.fill:  parent
    radius:        parent && parent.radius !== undefined ? parent.radius : 0
    color:         Qt.alpha(root.tintColor, ma.pressed
                        ? pressedOpacity
                        : (hoverEnabled && ma.containsMouse ? hoverOpacity : 0))

    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        id:       ma
        anchors.fill:     parent
        hoverEnabled:     root.hoverEnabled
        cursorShape:      root.cursorShape
        acceptedButtons:  root.acceptedButtons
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.rightClicked()
            else                                 root.clicked()
        }
    }
}
