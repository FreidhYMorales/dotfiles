pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects

// Clips source using maskSource shape.
// Caelestia API: maskSource
MultiEffect {
    id: root

    property Item maskSource: null

    maskEnabled:      true
    maskThresholdMin: 0.5
    maskSpreadAtMin:  1.0
}
