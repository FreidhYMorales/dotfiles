pragma ComponentBehavior: Bound

import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    property string icon:       ""
    property int    buttonSize: 64
    property int    iconSize:   24
    property bool   selected:   false

    signal activated()

    implicitWidth:  buttonSize
    implicitHeight: buttonSize

    HoverHandler { id: hov }

    readonly property bool active: hov.hovered || selected

    Text {
        anchors.centerIn: parent
        text:           root.icon
        font.family:    "Iosevka Term Nerd Font"
        font.pixelSize: root.iconSize
        color: root.active ? Colours.m3primary : Colours.m3onSurfaceVariant
        scale: root.active ? 1.35 : 1.0
        transformOrigin: Item.Center
        Behavior on color { CAnim {} }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.activated()
    }
}
