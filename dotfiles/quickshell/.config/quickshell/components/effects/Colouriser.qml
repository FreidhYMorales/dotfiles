pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects

// Recolors its source item.
// Caelestia API: colorizationColor, brightness
MultiEffect {
    id: root

    property color colorizationColor: "#ffffff"
    property real  brightness:        0

    colorization:  1.0
    blurEnabled:   false
}
