pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell.Wayland
import "../../services"
import "../../utils"

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock

    // LockConfig.lockScreenDisplay === false means "skip the idle screen,
    // go straight to the password field" (theme's loginState from the
    // start) — same distinction the original SDDM theme's Main.qml made
    // with its lockState/loginState initial state.
    property bool revealed: !LockConfig.lockScreenDisplay
    property bool bgFailed: false

    // Set by Lock.qml when services/IdleManager.qml's idle chain (not a
    // manual lock) triggered this session lock — keeps showing the same
    // screensaver content instead of jumping to the theme's own lock
    // background, until the first real input reveals the password prompt
    // (LockIdle's existing loginRequested() already gates that).
    property bool lockedViaIdle: false
    readonly property bool useScreensaverBg: root.lockedViaIdle && !root.revealed

    // Idle vs. auth ("lockState"/"loginState" in the theme's Main.qml) can
    // use different backgrounds/blur per .conf — e.g. default.conf drops the
    // blur to 0 once revealed, catppuccin-mocha.conf swaps to a flat color
    // background entirely instead of an image.
    readonly property string rawBackground: root.revealed ? LockConfig.loginScreenBackground : LockConfig.lockScreenBackground
    // "wallpaper" is a sentinel value (not a real filename under
    // lockBackgroundsDir) meaning "mirror the live desktop wallpaper" — set
    // by custom.conf. This must always resolve to Wallpapers.current
    // directly, NOT IdleManager.effectiveScreensaverSource: those two used
    // to always be identical (before the >screensaver panel existed, the
    // screensaver had no way to use a picture other than the desktop
    // wallpaper), but effectiveScreensaverSource can now point at a
    // deliberately different picture (screensaverUseWallpaper: false). The
    // screensaver's own idle-phase visual (useScreensaverBg below) SHOULD
    // still show that distinct picture — only the "wallpaper" sentinel
    // itself must stay pinned to the real wallpaper, same as the color
    // theming.
    readonly property bool useWallpaperBg: root.rawBackground === "wallpaper"
    readonly property bool useAbsoluteBgSource: root.useScreensaverBg || root.useWallpaperBg
    readonly property string bgSource: root.useScreensaverBg
        ? IdleManager.effectiveScreensaverSource
        : (root.useWallpaperBg ? Wallpapers.current : root.rawBackground)
    readonly property bool useBgColor: !root.useAbsoluteBgSource
        && (root.revealed ? LockConfig.loginScreenUseBackgroundColor : LockConfig.lockScreenUseBackgroundColor)
    readonly property color bgColor: root.revealed ? LockConfig.loginScreenBackgroundColor : LockConfig.lockScreenBackgroundColor
    readonly property int targetBlur: root.useScreensaverBg ? 0 : (root.revealed ? LockConfig.loginScreenBlur : LockConfig.lockScreenBlur)
    // MultiEffect.brightness/saturation range -1..1 with 0.0 == unchanged —
    // NOT 1.0 (that blows the image out to white, confirmed empirically).
    readonly property real targetBrightness: root.useScreensaverBg ? 0.0 : (root.revealed ? LockConfig.loginScreenBrightness : LockConfig.lockScreenBrightness)
    readonly property real targetSaturation: root.useScreensaverBg ? 0.0 : (root.revealed ? LockConfig.loginScreenSaturation : LockConfig.lockScreenSaturation)
    // .gifs are deliberately not supported here either — the theme itself
    // avoids them (Main.qml notes they crash SDDM with multiple monitors).
    readonly property bool isVideo: /\.(avi|mp4|mov|mkv|m4v|webm)$/i.test(root.bgSource)
    // Wallpapers.current (and IdleManager.effectiveScreensaverSource) start
    // "" until their async load finishes (persisted state FileView, or on a
    // fresh install the first wallpapers-folder scan) — without this guard,
    // the very first lock right after a cold Quickshell start could race
    // ahead of that, try to decode an empty path, and trip bgFailed
    // permanently for the whole lock session (stuck on default.jpg until
    // the NEXT lock, by which point the real path had long since loaded).
    readonly property bool bgPending: root.useAbsoluteBgSource && root.bgSource === ""
    readonly property bool showVideo: !root.useBgColor && !root.bgPending && root.isVideo && !root.bgFailed
    readonly property bool showImage: !root.useBgColor && !root.bgPending && (!root.isVideo || root.bgFailed)
    // bgSource.startsWith("/") (not useAbsoluteBgSource) on purpose: that
    // flag is a separately-cached property that can still be one tick stale
    // relative to bgSource itself when several LockConfig properties settle
    // together (e.g. right after its .conf finishes loading), which produced
    // a bogus doubled-up path (lockBackgroundsDir + an already-absolute
    // wallpaper path). Deriving "is this absolute" from bgSource's own
    // value in the same expression can't go stale relative to itself.
    readonly property url resolvedSource: root.bgFailed
        ? `file://${Paths.lockBackgroundsDir}/default.jpg`
        : (root.bgSource.startsWith("/") ? `file://${root.bgSource}` : `file://${Paths.lockBackgroundsDir}/${root.bgSource}`)

    onBgSourceChanged: root.bgFailed = false

    color: "black"

    Image {
        id: background
        anchors.fill: parent
        visible: root.showImage
        source: root.showImage ? root.resolvedSource : ""
        fillMode: LockConfig.backgroundFillMode === "stretch" ? Image.Stretch
            : LockConfig.backgroundFillMode === "fit" ? Image.PreserveAspectFit
            : Image.PreserveAspectCrop
        cache: true
        mipmap: true

        onStatusChanged: {
            // Guard against a transient race right after useScreensaverBg
            // flips: isVideo/showImage can lag one tick behind bgSource, so
            // this Image briefly tries to decode a video path as an image
            // and fails. Checking against THIS element's own `source` (what
            // actually failed) instead of the outer root.isVideo matters
            // because the failure is async — by the time it arrives,
            // root.bgSource/isVideo may have already moved on to the NEXT
            // source (e.g. right as `revealed` flips and the background
            // switches to the theme's login background). Trusting the
            // now-stale root.isVideo there incorrectly flagged the NEW,
            // perfectly valid image source as failed too.
            if (status === Image.Error && !root.bgFailed) {
                const failedWasVideo = /\.(avi|mp4|mov|mkv|m4v|webm)$/i.test(background.source.toString())
                // Deferred: setting bgFailed synchronously here feeds back
                // into resolvedSource (which this Image's own `source` binds
                // to), and if LockConfig/Wallpapers happen to settle several
                // upstream properties in the same update batch (cfg reload,
                // revealed's config-driven initial value, etc.), that
                // same-tick feedback can trip QML's binding-loop detector.
                // Qt.callLater pushes the write to the next tick, same
                // observable result, no reentrancy.
                if (!failedWasVideo) Qt.callLater(() => { root.bgFailed = true })
            }
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
        fillMode: LockConfig.backgroundFillMode === "stretch" ? VideoOutput.Stretch
            : LockConfig.backgroundFillMode === "fit" ? VideoOutput.PreserveAspectFit
            : VideoOutput.PreserveAspectCrop

        onErrorOccurred: (error, errorString) => {
            if (!root.bgFailed) root.bgFailed = true
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.useBgColor
        color: root.bgColor
    }

    MultiEffect {
        id: backgroundEffect
        source: root.isVideo && !root.bgFailed ? backgroundVideo : background
        anchors.fill: parent
        visible: !root.useBgColor
        blurEnabled: root.targetBlur > 0
        blur: root.targetBlur > 0 ? 1.0 : 0.0
        blurMax: root.targetBlur
        brightness: root.targetBrightness
        saturation: root.targetSaturation
        autoPaddingEnabled: false

        Behavior on blurMax { NumberAnimation { duration: 400 } }
        Behavior on brightness { NumberAnimation { duration: 400 } }
        Behavior on saturation { NumberAnimation { duration: 400 } }
    }

    LockIdle {
        id: idle
        anchors.fill: parent
        visible: opacity > 0
        opacity: root.revealed ? 0 : 1
        focus: !root.revealed
        contentVisible: !root.useScreensaverBg
        // Idle-triggered lock: within the grace window (before
        // IdleManager.lockGraceElapsed), input dismisses for free — the
        // session was only locked early to keep the screensaver's media
        // pipeline from ever restarting, not because a password is due yet.
        // Once the grace window has also elapsed, or for a manual lock
        // (dashboard/keybind, lockedViaIdle false), input reveals the real
        // password prompt as before.
        onLoginRequested: {
            if (root.lockedViaIdle && !IdleManager.lockGraceElapsed) root.lock.locked = false
            else root.revealed = true
        }

        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    LockAuth {
        id: auth
        anchors.fill: parent
        lock: root.lock
        visible: opacity > 0
        opacity: root.revealed ? 1 : 0
        focus: root.revealed
        onCloseRequested: root.revealed = false

        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
}
