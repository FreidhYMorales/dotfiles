pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Typography
    property string fontFamily: "DepartureMono Nerd Font"

    // Corner Radii (0 for terminal-alike square aesthetic)
    property int cornerRadius: 0
    property int cornerRadiusSmall: 0
    property int cornerRadiusMedium: 0
    property int cornerRadiusLarge: 0

    // Corner style toggle
    property bool isSquare: true
}
