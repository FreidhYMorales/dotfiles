pragma ComponentBehavior: Bound
import QtQuick

// Material Design state layer (hover/press tint overlay).
Rectangle {
    id: root

    property color  tintColor:      "#ffffff"
    property real   hoverOpacity:   0.08
    property real   pressedOpacity: 0.12
    property bool   hoverEnabled:   true
    property int    cursorShape:    Qt.ArrowCursor

    signal clicked()

    anchors.fill:  parent
    radius:        parent ? parent.radius : 0
    color:         Qt.alpha(root.tintColor, ma.pressed
                        ? pressedOpacity
                        : (hoverEnabled && ma.containsMouse ? hoverOpacity : 0))

    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        id:       ma
        anchors.fill:  parent
        hoverEnabled:  root.hoverEnabled
        cursorShape:   root.cursorShape
        onClicked:     root.clicked()
    }
}
