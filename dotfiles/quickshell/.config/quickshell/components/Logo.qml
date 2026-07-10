pragma ComponentBehavior: Bound
import QtQuick

// Project logo placeholder. Replace with actual SVG/Image when available.
Item {
    id: root
    property int size: 32
    implicitWidth:  size
    implicitHeight: size

    Text {
        anchors.centerIn: parent
        text:           ""
        font.family:    "Iosevka Term Nerd Font"
        font.pixelSize: Math.round(root.size * 0.7)
        color:          "#cdd6f4"
    }
}
