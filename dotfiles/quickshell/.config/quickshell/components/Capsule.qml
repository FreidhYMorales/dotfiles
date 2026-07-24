import QtQuick
import "../services"

// Terminal-alike bordered card — the dashboard's shared capsule chrome
// (profile panel, notification, weather, battery+performance, music).
Rectangle {
    radius: Style.cornerRadius
    color:  Colours.layer(Colours.m3surfaceContainer, 2)
    border.width: 2
    border.color: Qt.alpha(Colours.m3primary, 0.9)
    Behavior on color { CAnim {} }
}
