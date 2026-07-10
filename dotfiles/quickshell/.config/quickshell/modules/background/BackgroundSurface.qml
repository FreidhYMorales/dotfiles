pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import "../../services"

// Desktop wallpaper renderer — Image+Video pattern ported from
// modules/lock/LockSurface.qml. Rendered by Quickshell itself (Background.qml,
// one WlrLayershell "background" layer per monitor) instead of hyprpaper, so
// video wallpapers work and preview swaps while browsing the launcher's
// wallpaper picker are instant property changes, not IPC round-trips.
Item {
    id: root

    required property string screenName

    property bool bgFailed: false

    readonly property string bgSource: Wallpapers.currentFor(root.screenName)
    readonly property bool isVideo: Wallpapers.isVideoPath(root.bgSource)
    readonly property bool showVideo: root.isVideo && !root.bgFailed
    readonly property bool showImage: !root.isVideo || root.bgFailed
    readonly property url resolvedSource: root.bgSource === "" ? "" : `file://${root.bgSource}`

    onBgSourceChanged: root.bgFailed = false

    Image {
        id: background
        anchors.fill: parent
        visible: root.showImage
        source: root.showImage ? root.resolvedSource : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        mipmap: true

        // Crossfade instead of a hard cut when the source changes (preview
        // browsing or a commit) — dips to 0 while the new image decodes,
        // back to 1 once ready.
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        onStatusChanged: {
            if (status === Image.Error && !root.bgFailed) root.bgFailed = true
        }
    }

    Video {
        id: backgroundVideo
        anchors.fill: parent
        visible: root.showVideo
        source: root.showVideo ? root.resolvedSource : ""
        autoPlay: root.showVideo
        loops: MediaPlayer.Infinite
        muted: true
        fillMode: VideoOutput.PreserveAspectCrop

        // Video (the QtMultimedia convenience type) doesn't expose the
        // underlying MediaPlayer's mediaStatus — hasVideo is the closest
        // "a frame is decodable" signal it aliases.
        opacity: hasVideo ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        onErrorOccurred: (error, errorString) => {
            if (!root.bgFailed) root.bgFailed = true
        }
    }
}
