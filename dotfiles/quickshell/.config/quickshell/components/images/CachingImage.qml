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

    // Decode at the actual displayed resolution instead of the source's
    // native size — avoids blur on HiDPI (no downsampling hint otherwise)
    // and avoids wasting memory decoding oversized icons/thumbnails.
    sourceSize.width:  root.width  > 0 ? Math.round(root.width  * Screen.devicePixelRatio) : undefined
    sourceSize.height: root.height > 0 ? Math.round(root.height * Screen.devicePixelRatio) : undefined
}
