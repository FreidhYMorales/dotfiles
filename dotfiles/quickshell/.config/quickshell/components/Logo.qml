pragma ComponentBehavior: Bound
import QtQuick
import "../services"

// Project logo placeholder. Replace with actual SVG/Image when available.
Item {
    id: root
    property int size: 32
    implicitWidth:  size
    implicitHeight: size

    Text {
        anchors.centerIn: parent
        text:           ""
        font.family:    Style.fontFamily
        font.pixelSize: Math.round(root.size * 0.7)
        color:          "#cdd6f4"
    }
}
