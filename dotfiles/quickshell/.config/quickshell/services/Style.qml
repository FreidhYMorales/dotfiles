pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Typography
    property string fontFamily:     "DepartureMono Nerd Font"
    property string fontFamilyMono: "DepartureMono Nerd Font Mono"

    // Corner Radii (0 for terminal-alike square aesthetic)
    property int cornerRadius: 0
    property int cornerRadiusSmall: 0
    property int cornerRadiusMedium: 0
    property int cornerRadiusLarge: 0

    // Corner style toggle
    property bool isSquare: true

    // Helper function to return radius based on square preference
    function radius(roundedValue: int): int {
        return root.isSquare ? 0 : roundedValue
    }
}
