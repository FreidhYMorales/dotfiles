pragma ComponentBehavior: Bound
import QtQuick

// Crossfading loader. Caelestia API: sourceComp (alias for sourceComponent).
Item {
    id: root

    // Caelestia uses sourceComp, not sourceComponent
    property Component sourceComp: null
    property int fadeDuration: 150

    Loader {
        id: ldr
        anchors.fill: parent
        sourceComponent: root.sourceComp

        onSourceComponentChanged: {
            ldr.opacity = 0
            swapTimer.restart()
        }

        Behavior on opacity { NumberAnimation { duration: root.fadeDuration } }
    }

    Timer {
        id: swapTimer
        interval: root.fadeDuration
        onTriggered: {
            ldr.sourceComponent = root.sourceComp
            ldr.opacity = 1
        }
    }
}
