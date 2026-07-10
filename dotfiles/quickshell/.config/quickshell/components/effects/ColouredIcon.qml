pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects

// Recolors an icon image to the specified color.
// Caelestia API: source, colour, implicitSize
Item {
    id: root

    property url    source:      ""
    property color  colour:      "#ffffff"
    property real   implicitSize: 24

    implicitWidth:  implicitSize
    implicitHeight: implicitSize

    Image {
        id: img
        anchors.fill:  parent
        source:        root.source
        visible:       false
        smooth:        true
        asynchronous:  true
        fillMode:      Image.PreserveAspectFit
    }

    MultiEffect {
        source:              img
        anchors.fill:        img
        colorization:        1.0
        colorizationColor:   root.colour
    }
}
