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
    property string previewPath: ""
    property bool showPreview: false
    // Effective wallpaper the background module should render.
    readonly property string current: showPreview ? previewPath : actualCurrent

    function preview(path) {
        root.previewPath = path
        root.showPreview = true
    }

    function stopPreview() {
        root.showPreview = false
    }

    function commit(path) {
        root.actualCurrent = path
        root.showPreview = false
        root._persist()
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

    Component.onCompleted: {
        mkStateDirProc.running = true
        mkThumbDirProc.running = true
    }
}
