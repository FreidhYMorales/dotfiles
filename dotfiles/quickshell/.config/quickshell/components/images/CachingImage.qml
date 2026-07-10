pragma ComponentBehavior: Bound
import QtQuick

// Image with caching and path alias.
// Caelestia API: path (alias for source)
Image {
    id: root

    // path is Caelestia's alias for source
    property url path: ""

    source:       root.path
    cache:        true
    asynchronous: true
    smooth:       true
    fillMode:     Image.PreserveAspectCrop
}
