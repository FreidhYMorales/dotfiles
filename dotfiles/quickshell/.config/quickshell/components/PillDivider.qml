import QtQuick
import "../services"

// 2px vertical divider between widgets inside a bar pill — repeated
// verbatim across BarContent.qml's leftPill/midPill/rightPill rows, once
// per widget boundary.
Rectangle {
    id: root

    property real pillHeight: 26
    property var  colors:     Colours.palette

    width:  2
    height: root.pillHeight - 4
    anchors.verticalCenter: parent.verticalCenter
    antialiasing: false
    color: Colours.mid(root.colors.m3surfaceContainer, root.colors.m3surfaceContainerHigh)
}
