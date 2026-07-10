pragma ComponentBehavior: Bound
import QtQuick

// Image that crossfades when source changes.
// Also exposes Image properties directly (asynchronous, fillMode, sourceSize, status).
Image {
    id: root

    property color backgroundColor: "transparent"

    asynchronous: true
    smooth:       true
    cache:        true
    fillMode:     Image.PreserveAspectCrop

    Behavior on opacity { NumberAnimation { duration: 300 } }
}
