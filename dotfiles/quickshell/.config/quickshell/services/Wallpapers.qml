pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../utils"

// Scans Paths.wallpapersDir for images/videos, tracks the committed vs.
// previewed wallpaper, and persists the choice across restarts. The desktop
// background (modules/background/) binds to `current`, so preview() swaps
// the real background live while browsing the launcher's wallpaper picker.
Singleton {
    id: root

    function isVideoPath(path) {
        return /\.(avi|mp4|mov|mkv|m4v|webm)$/i.test(path)
    }

    // The laptop's own built-in display — Linux always names embedded
    // panels eDP-* (unlike external monitors: HDMI-A-*, DP-*, etc). Its
    // wallpaper commit IS the shared/global one (drives colors.json +
    // kitty/Hyprland/btop/SDDM), not an independent per-monitor override —
    // "the general theme" == "the laptop's own screen". On a desktop-only
    // setup (no eDP output at all) this is false for every screen, so every
    // monitor keeps its own independent override exactly as before, and the
    // launcher's "All" tab remains the only way to set the shared one.
    function isPrimaryScreen(screenName) {
        return !!screenName && screenName.startsWith("eDP")
    }

    // --- directory scan ---
    FolderListModel {
        id: folderModel
        folder: "file://" + Paths.wallpapersDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp",
                      "*.avi", "*.mp4", "*.mov", "*.mkv", "*.m4v", "*.webm"]
        showDirs: false
        sortField: FolderListModel.Name

        onCountChanged: root._rebuildEntries()
        onStatusChanged: {
            if (status !== FolderListModel.Ready) return
            root._rebuildEntries()
            // First-run fallback: only if nothing was restored from disk yet.
            if (!root._restored && root.actualCurrent === "" && root.entries.length > 0)
                root.actualCurrent = root.entries[0].path
        }
    }

    property var entries: []

    function _rebuildEntries() {
        const out = []
        for (let i = 0; i < folderModel.count; i++) {
            const path = folderModel.get(i, "filePath")
            out.push({ path: path, name: folderModel.get(i, "fileName"), isVideo: root.isVideoPath(path) })
        }
        root.entries = out
    }

    // --- video thumbnail cache (for the ">wallpaper" carousel's video cards) ---
    // Same ffmpegthumbnailer approach as Colours.qml's matugen frame
    // extraction, but keyed per-video-path (not a single shared path) since
    // several video wallpapers can need a thumbnail at once. One entry per
    // path: "" means pending/failed (icon glyph fallback stays visible),
    // a real path means the PNG is ready to show.
    property var videoFrameCache: ({})
    property var _frameQueue: []
    property bool _frameExtracting: false

    function requestVideoFrame(path) {
        if (!Colours.ffmpegthumbnailerAvailable) return
        if (root.videoFrameCache[path] !== undefined) return // already done or queued
        root.videoFrameCache = Object.assign({}, root.videoFrameCache, { [path]: "" })
        root._frameQueue.push(path)
        root._processFrameQueue()
    }

    function _thumbFileFor(path) {
        const base = path.split("/").pop().replace(/\.[^.]+$/, "")
        return `${Paths.cache}/quickshell-wallpaper-thumbs/${base.replace(/[^a-zA-Z0-9_-]/g, "_")}.png`
    }

    function _processFrameQueue() {
        if (root._frameExtracting || root._frameQueue.length === 0) return
        root._frameExtracting = true
        const path = root._frameQueue.shift()
        frameExtractProc._pendingPath = path
        frameExtractProc._pendingOut  = root._thumbFileFor(path)
        frameExtractProc.command = ["ffmpegthumbnailer", "-i", path, "-o", frameExtractProc._pendingOut, "-s", "512"]
        frameExtractProc.running = true
    }

    Process {
        id: mkThumbDirProc
        command: ["mkdir", "-p", `${Paths.cache}/quickshell-wallpaper-thumbs`]
    }

    Process {
        id: frameExtractProc
        property string _pendingPath: ""
        property string _pendingOut:  ""
        onExited: exitCode => {
            const ok = exitCode === 0
            root.videoFrameCache = Object.assign({}, root.videoFrameCache,
                { [frameExtractProc._pendingPath]: ok ? frameExtractProc._pendingOut : "" })
            root._frameExtracting = false
            root._processFrameQueue()
        }
    }

    // --- state ---
    property bool _restored: false
    property string actualCurrent: ""
    // Per-monitor overrides, keyed by ShellScreen.name — a screen with no
    // entry here just follows actualCurrent. Empty object means every
    // monitor is in sync (the common/default case).
    property var perScreen: ({})
    property string previewPath: ""
    // "" while previewing means "all monitors" (mirrors commit's screenName
    // convention below); a specific screen name scopes the preview to just
    // that monitor while browsing the launcher's per-monitor tab.
    property string previewScreen: ""
    property bool showPreview: false
    // Effective wallpaper the background module should render. Kept for
    // single-output consumers that have no per-monitor concept of their own
    // (lock screen background sentinel, screensaver-uses-wallpaper mode).
    readonly property string current: showPreview ? previewPath : actualCurrent

    // Per-monitor equivalent of `current`, for modules/background/Background.qml
    // (one BackgroundSurface per ShellScreen).
    function currentFor(screenName) {
        if (root.showPreview && (root.previewScreen === "" || root.previewScreen === screenName))
            return root.previewPath
        const override = root.perScreen[screenName]
        return override !== undefined ? override : root.actualCurrent
    }

    function preview(path, screenName) {
        root.previewPath   = path
        root.previewScreen = screenName ?? ""
        root.showPreview   = true
    }

    function stopPreview() {
        root.showPreview = false
    }

    // screenName "" is the explicit "All" tab: commits the shared default
    // AND clears every per-monitor override — the deliberate "use the same
    // wallpaper on every monitor" sync action. screenName === the laptop's
    // own screen (isPrimaryScreen) ALSO commits the shared default (that IS
    // the general theme — see LauncherContent's monitor tabs), but must NOT
    // clear other monitors' overrides just because you changed your own
    // laptop wallpaper — only the "All" tab does that, deliberately. Any
    // other screenName is a real per-monitor override, untouched by either.
    function commit(path, screenName) {
        root.showPreview = false
        if (screenName && !root.isPrimaryScreen(screenName)) {
            // Per-monitor override: recolors ONLY that monitor's bar/panels
            // (Colours.regeneratePaletteFor, via matugen --dry-run) — never
            // touches the shell's single global theme or the external-app
            // pipeline (colors.json/kitty/Hyprland/btop/SDDM stay tied to
            // the shared default below).
            root.perScreen = Object.assign({}, root.perScreen, { [screenName]: path })
            root._persistPerScreen()
            Colours.regeneratePaletteFor(screenName, path, root.isVideoPath(path))
            return
        }
        root.actualCurrent = path
        root._persist()
        // Only the explicit "All" tab (screenName === "") also syncs —
        // clearing every per-monitor override so every screen follows this
        // wallpaper. The primary screen's own tab must leave other
        // monitors' independent overrides exactly as they were.
        if (!screenName) {
            root.perScreen = {}
            root._persistPerScreen()
            Colours.clearScreenPalettes()
        }
        // "dynamic" mode: recompute the APPLIED colors from the new
        // wallpaper. A manual theme-mode commit (Colours.commit) always
        // regenerates regardless.
        if (Colours.dynamic) Colours.regenerateFrom(path, root.isVideoPath(path))
        // Always refresh the ">theme" picker's swatch previews to match the
        // new wallpaper, so they're not still showing the old one.
        Colours.generatePreviews(path, root.isVideoPath(path))
    }

    // --- persistence (~/.local/state/quickshell/wallpaper.txt) ---
    Process {
        id: mkStateDirProc
        command: ["mkdir", "-p", Paths.appState]
    }

    FileView {
        id: stateFile
        path: Paths.wallpaperStatePath
        watchChanges: false
        onLoaded: {
            const saved = text().trim()
            if (saved.length > 0) {
                root.actualCurrent = saved
                root._restored = true
            }
        }
        onLoadFailed: {} // no state yet — first-run fallback above handles it
    }

    function _persist() {
        mkStateDirProc.running = true
        stateFile.setText(root.actualCurrent)
    }

    FileView {
        id: perScreenStateFile
        path: Paths.wallpaperPerScreenStatePath
        watchChanges: false
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                if (saved && typeof saved === "object") {
                    root.perScreen = saved
                    // Palettes aren't persisted (only the wallpaper paths
                    // are) — recompute one per restored override on startup.
                    for (const screenName in saved)
                        Colours.regeneratePaletteFor(screenName, saved[screenName], root.isVideoPath(saved[screenName]))
                }
            } catch (e) {
                console.warn("Wallpapers: failed to parse per-screen state:", e)
            }
        }
        onLoadFailed: {} // no per-monitor overrides saved yet
    }

    function _persistPerScreen() {
        mkStateDirProc.running = true
        perScreenStateFile.setText(JSON.stringify(root.perScreen))
    }

    Component.onCompleted: {
        mkStateDirProc.running = true
        mkThumbDirProc.running = true
    }
}
