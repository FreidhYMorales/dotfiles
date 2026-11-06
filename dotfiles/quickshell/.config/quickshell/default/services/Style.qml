pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Typography
    property string fontFamily: "DepartureMono Nerd Font"

    // Corner Radii (Caelestia-esque rounded default — was 0/0/0/0 for the
    // prior terminal-alike square aesthetic). Relative sizing kept
    // consistent across tiers: small < base < medium < large.
    property int cornerRadius: 8
    property int cornerRadiusSmall: 6
    property int cornerRadiusMedium: 10
    property int cornerRadiusLarge: 16
}
