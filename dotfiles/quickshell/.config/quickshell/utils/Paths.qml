pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property string home:   Quickshell.env("HOME")
    readonly property string config: Quickshell.env("XDG_CONFIG_HOME")  || `${home}/.config`
    readonly property string state:  Quickshell.env("XDG_STATE_HOME")   || `${home}/.local/state`
    readonly property string cache:  Quickshell.env("XDG_CACHE_HOME")   || `${home}/.cache`
    readonly property string data:   Quickshell.env("XDG_DATA_HOME")    || `${home}/.local/share`

    readonly property string shell:          `${config}/quickshell/deadlock`
    readonly property string matugenColors:  `${config}/matugen/colors.json`
    readonly property string scripts:        Qt.resolvedUrl("../scripts").toString().replace("file://", "")

    // Caelestia-compatible paths
    readonly property string notifimagecache: `${cache}/caelestia/imagecache/notifs`

    // Lock module — assets ported from the SDDM "silent" theme
    readonly property string lockAssets:      Qt.resolvedUrl("../modules/lock/assets").toString().replace("file://", "")
    readonly property string lockConfigDir:   `${lockAssets}/configs`
    readonly property string lockIconsDir:    `${lockAssets}/icons`
    readonly property string lockBackgroundsDir: `${lockAssets}/backgrounds`
    readonly property string activeLockConfig: Quickshell.env("QS_LOCK_THEME") || "custom"
    // Root to add to QML_IMPORT_PATH so Qt can find
    // QtQuick/VirtualKeyboard/Styles/LockKeyboard/style.qml — documented
    // here for reference; QML has no API to set this env var for the
    // already-running engine, it must be exported before `qs` starts.
    readonly property string lockVkeyboardStylesDir: `${lockAssets}/vkeyboard-styles`

    // Wallpaper picker + theming-mode picker
    readonly property string wallpapersDir:   Quickshell.env("QS_WALLPAPER_DIR") || `${home}/Pictures/Wallpaper`
    readonly property string appState:        `${state}/quickshell`
    readonly property string wallpaperStatePath: `${appState}/wallpaper.txt`
    readonly property string wallpaperPerScreenStatePath: `${appState}/wallpaper-screens.json`
    readonly property string themeStatePath:  `${appState}/theme.json`
    readonly property string idleStatePath:   `${appState}/idle.json`
    readonly property string weatherLocPath:  `${appState}/weather-loc.json`

    // Screen recording (services/Recorder.qml) — session-only state, no
    // persistence file, just an output folder.
    readonly property string recordingsDir: Quickshell.env("QS_RECORDINGS_DIR") || `${home}/Videos/Recordings`

    // Resolves a path relative to home, handling ~ and $HOME expansion
    function absolutePath(path) {
        if (!path) return ""
        return (path || "").replace(/^~/, home).replace(/^\$({?HOME}?)/, home)
    }
}
