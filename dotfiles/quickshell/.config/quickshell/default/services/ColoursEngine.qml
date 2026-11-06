import Quickshell
import Quickshell.Io
import QtQuick
import "../utils"

// matugen/ffmpegthumbnailer process orchestration for Colours — single-shot
// recolor (regenerateFrom), per-monitor palette regeneration (used by the
// wallpaper picker's per-screen overrides), and the launcher's ">theme"
// swatch previews. Split out of Colours.qml because none of this needs to
// BE a singleton; it just needs Colours' currentMode/isLight/fallback
// colors to build matugen's CLI args and dry-run fallbacks, read live off
// `owner`. Colours.qml keeps its m3* properties and parse() (the actually-
// applied color state) and forwards these calls/properties through.
// Item (not QtObject) so the Process/StdioCollector children below can be
// declared directly — QtObject has no default property to parent them to.
Item {
    id: engine

    required property QtObject owner

    property bool matugenAvailable: false
    property bool ffmpegthumbnailerAvailable: false

    Process {
        id: checkMatugenProc
        command: ["which", "matugen"]
        onExited: exitCode => engine.matugenAvailable = (exitCode === 0)
    }
    Process {
        id: checkFfmpegthumbnailerProc
        command: ["which", "ffmpegthumbnailer"]
        onExited: exitCode => engine.ffmpegthumbnailerAvailable = (exitCode === 0)
    }

    Component.onCompleted: {
        checkMatugenProc.running = true
        checkFfmpegthumbnailerProc.running = true
    }

    // --- Single-source regeneration (Colours.commit → global recolor) ---

    readonly property string _videoFramePath: `${Paths.cache}/quickshell-wallpaper-frame.png`

    Process { id: extractFrameProc; property var onDone: null }
    Process {
        id: matugenProc
        onExited: exitCode => {
            if (exitCode === 0) postHookProc.running = true
            else console.warn("Colours: matugen exited with code", exitCode)
        }
    }
    Process {
        id: postHookProc
        command: [Paths.home + "/.config/matugen/post-hook.sh", engine.owner.isLight ? "light" : "dark"]
    }

    // path/isVideo describe the SOURCE (wallpaper) to derive colors from;
    // owner.currentMode/isLight (already committed) pick the scheme type.
    function regenerateFrom(path, isVideo) {
        if (!path || !engine.matugenAvailable) return
        if (isVideo) {
            engine._extractFrame(path, engine._runMatugen)
        } else {
            engine._runMatugen(path)
        }
    }

    // Shared by regenerateFrom (single commit) and generatePreviews (batch
    // swatches) — both need the same "extract a frame first if it's a video"
    // step before matugen can read a source image.
    function _extractFrame(videoPath, onDone) {
        if (!engine.ffmpegthumbnailerAvailable) return
        extractFrameProc.onDone = onDone
        extractFrameProc.command = ["ffmpegthumbnailer", "-i", videoPath, "-o", engine._videoFramePath, "-s", "512"]
        extractFrameProc.exited.connect(engine._onFrameExtracted)
        extractFrameProc.running = true
    }

    function _onFrameExtracted(exitCode) {
        extractFrameProc.exited.disconnect(engine._onFrameExtracted)
        if (exitCode === 0 && extractFrameProc.onDone) extractFrameProc.onDone(engine._videoFramePath)
        extractFrameProc.onDone = null
    }

    function _runMatugen(imagePath) {
        matugenProc.command = ["matugen", "image", imagePath,
            "--type", engine.owner.currentMode,
            "--mode", engine.owner.isLight ? "light" : "dark",
            "--source-color-index", "0",
            "--quiet"]
        matugenProc.running = true
    }

    // --- Per-monitor palettes (bar/panels only — see Colours.paletteFor) ---
    // Keyed by ShellScreen.name. A screen with no entry here just follows
    // the global flat m3* properties/`palette` (shared default).
    property var palettes: ({})

    function clearScreenPalettes() {
        engine.palettes = {}
    }

    // Same field mapping as Colours.parse(), but returned as a plain object
    // instead of mutated onto the singleton — used for per-monitor palettes,
    // which must NEVER touch the globally-applied colors or external apps.
    //
    // Note: this reads matugen's own `--json hex` dump shape (used for
    // --dry-run calls), which nests each color as
    // { default: { color }, dark: { color }, light: { color } } — NOT the
    // { hex } shape that the real colors.json (written by our OWN
    // colors.json.template) uses in Colours.parse(). "default" already
    // reflects whichever --mode light/dark was requested on the CLI, same
    // as the existing _runNextPreview swatch reader.
    function _extractPalette(data) {
        if (!data?.colors) return null
        const c = data.colors
        const o = engine.owner
        return {
            m3primary:                 c.primary?.default?.color                   ?? o.m3primary,
            m3onPrimary:               c.on_primary?.default?.color                ?? o.m3onPrimary,
            m3primaryContainer:        c.primary_container?.default?.color         ?? o.m3primaryContainer,
            m3onPrimaryContainer:      c.on_primary_container?.default?.color      ?? o.m3onPrimaryContainer,
            m3secondary:               c.secondary?.default?.color                 ?? o.m3secondary,
            m3onSecondary:             c.on_secondary?.default?.color              ?? o.m3onSecondary,
            m3secondaryContainer:      c.secondary_container?.default?.color       ?? o.m3secondaryContainer,
            m3onSecondaryContainer:    c.on_secondary_container?.default?.color    ?? o.m3onSecondaryContainer,
            m3tertiary:                c.tertiary?.default?.color                  ?? o.m3tertiary,
            m3onTertiary:              c.on_tertiary?.default?.color               ?? o.m3onTertiary,
            m3tertiaryContainer:       c.tertiary_container?.default?.color        ?? o.m3tertiaryContainer,
            m3onTertiaryContainer:     c.on_tertiary_container?.default?.color     ?? o.m3onTertiaryContainer,
            m3background:              c.background?.default?.color                ?? o.m3background,
            m3onBackground:            c.on_background?.default?.color             ?? o.m3onBackground,
            m3surface:                 c.surface?.default?.color                   ?? o.m3surface,
            m3onSurface:               c.on_surface?.default?.color                ?? o.m3onSurface,
            m3surfaceDim:              c.surface_dim?.default?.color               ?? o.m3surfaceDim,
            m3surfaceBright:           c.surface_bright?.default?.color            ?? o.m3surfaceBright,
            m3surfaceContainerLowest:  c.surface_container_lowest?.default?.color  ?? o.m3surfaceContainerLowest,
            m3surfaceContainerLow:     c.surface_container_low?.default?.color     ?? o.m3surfaceContainerLow,
            // Same token kitty's background uses (c.surface, not surface_container)
            // so the bar/panels read as the same "terminal surface" color.
            m3surfaceContainer:        c.surface?.default?.color                   ?? o.m3surfaceContainer,
            m3surfaceContainerHigh:    c.surface_container_high?.default?.color    ?? o.m3surfaceContainerHigh,
            m3surfaceContainerHighest: c.surface_container_highest?.default?.color ?? o.m3surfaceContainerHighest,
            m3onSurfaceVariant:        c.on_surface_variant?.default?.color        ?? o.m3onSurfaceVariant,
            m3outline:                 c.outline?.default?.color                   ?? o.m3outline,
            m3outlineVariant:          c.outline_variant?.default?.color           ?? o.m3outlineVariant,
            m3error:                   c.error?.default?.color                     ?? o.m3error,
            m3onError:                 c.on_error?.default?.color                  ?? o.m3onError,
            m3errorContainer:          c.error_container?.default?.color           ?? o.m3errorContainer,
            m3onErrorContainer:        c.on_error_container?.default?.color        ?? o.m3onErrorContainer,
            m3inverseSurface:          c.inverse_surface?.default?.color           ?? o.m3inverseSurface,
            m3inverseOnSurface:        c.inverse_on_surface?.default?.color        ?? o.m3inverseOnSurface,
            m3inversePrimary:          c.inverse_primary?.default?.color           ?? o.m3inversePrimary,
            m3scrim:                   c.scrim?.default?.color                     ?? o.m3scrim,
            m3shadow:                  c.shadow?.default?.color                    ?? o.m3shadow
        }
    }

    // Queued (not parallel) like generatePreviews below — same reasoning:
    // several monitors can request a regen close together (startup restore,
    // a global scheme change looping every override) and shouldn't spawn N
    // matugen processes at once.
    property var _screenPaletteQueue: []
    property bool _screenPaletteBusy: false
    readonly property string _screenPaletteFramePath: `${Paths.cache}/quickshell-screen-palette-frame.png`
    Process { id: screenPaletteExtractFrameProc; property var onDone: null }

    function regeneratePaletteFor(screenName, path, isVideo) {
        if (!screenName || !path || !engine.matugenAvailable) return
        engine._screenPaletteQueue.push({ screenName: screenName, path: path, isVideo: isVideo })
        engine._runNextScreenPalette()
    }

    function _runNextScreenPalette() {
        if (engine._screenPaletteBusy || engine._screenPaletteQueue.length === 0) return
        engine._screenPaletteBusy = true
        const job = engine._screenPaletteQueue.shift()
        if (job.isVideo) {
            engine._extractFrameForScreenPalette(job.path, framePath => engine._execScreenPalette(job.screenName, framePath))
        } else {
            engine._execScreenPalette(job.screenName, job.path)
        }
    }

    function _extractFrameForScreenPalette(videoPath, onDone) {
        if (!engine.ffmpegthumbnailerAvailable) {
            engine._screenPaletteBusy = false
            engine._runNextScreenPalette()
            return
        }
        screenPaletteExtractFrameProc.onDone = onDone
        screenPaletteExtractFrameProc.command = ["ffmpegthumbnailer", "-i", videoPath, "-o", engine._screenPaletteFramePath, "-s", "512"]
        screenPaletteExtractFrameProc.exited.connect(engine._onScreenPaletteFrameExtracted)
        screenPaletteExtractFrameProc.running = true
    }

    function _onScreenPaletteFrameExtracted(exitCode) {
        screenPaletteExtractFrameProc.exited.disconnect(engine._onScreenPaletteFrameExtracted)
        if (exitCode === 0 && screenPaletteExtractFrameProc.onDone) {
            screenPaletteExtractFrameProc.onDone(engine._screenPaletteFramePath)
        } else {
            engine._screenPaletteBusy = false
            engine._runNextScreenPalette()
        }
        screenPaletteExtractFrameProc.onDone = null
    }

    function _execScreenPalette(screenName, imagePath) {
        screenPaletteProc.pendingScreen = screenName
        screenPaletteProc.command = ["matugen", "image", imagePath,
            "--type", engine.owner.currentMode,
            "--mode", engine.owner.isLight ? "light" : "dark",
            "--source-color-index", "0",
            "--dry-run", "--quiet",
            "--json", "hex"]
        screenPaletteProc.running = true
    }

    Process {
        id: screenPaletteProc
        property string pendingScreen: ""
        stdout: StdioCollector {
            id: screenPaletteStdout
            onStreamFinished: {
                try {
                    const data   = JSON.parse(screenPaletteStdout.text)
                    const parsed = engine._extractPalette(data)
                    if (parsed) {
                        const next = Object.assign({}, engine.palettes)
                        next[screenPaletteProc.pendingScreen] = parsed
                        engine.palettes = next
                    }
                } catch (e) {
                    console.warn("Colours: failed to parse per-screen palette json for", screenPaletteProc.pendingScreen, e)
                }
                engine._screenPaletteBusy = false
                engine._runNextScreenPalette()
            }
        }
    }

    // --- Theme mode swatch previews (launcher's ">theme" picker) ---
    // Generates a real primary/secondary/tertiary swatch per mode against the
    // CURRENT wallpaper, one matugen call at a time (queued, not parallel, so
    // opening the picker doesn't spawn 9 processes at once). Uses --dry-run
    // --json so nothing gets written to the real colors.json — this must
    // never affect the actually-applied colors, only the cache below.
    property var previewCache: ({})
    property var _previewQueue: []

    Process {
        id: previewProc
        property string pendingMode: ""
        // StdioCollector instead of manually accumulating SplitParser lines:
        // the dry-run JSON dump is large (~18KB, hundreds of lines), and
        // reading the buffer from onRunningChanged raced the last chunks of
        // stdout still arriving — every mode failed to JSON.parse when the
        // source was a video-extracted frame (bigger/slower matugen run made
        // the race obvious, but it's not exclusive to video). streamFinished
        // only fires once the full stream is captured.
        stdout: StdioCollector {
            id: previewStdout
            onStreamFinished: {
                try {
                    const data = JSON.parse(previewStdout.text)
                    // Reassign (not mutate) so the property's own change
                    // notification fires and ThemeModeItem's binding re-evaluates.
                    const next = Object.assign({}, engine.previewCache)
                    next[previewProc.pendingMode] = {
                        primary:   data.colors.primary.default.color,
                        secondary: data.colors.secondary.default.color,
                        tertiary:  data.colors.tertiary.default.color
                    }
                    engine.previewCache = next
                } catch (e) {
                    console.warn("Colours: failed to parse preview json for", previewProc.pendingMode, e)
                }
                engine._runNextPreview()
            }
        }
    }

    function generatePreviews(wallpaperPath, isVideo) {
        if (!wallpaperPath || !engine.matugenAvailable) return
        engine.previewCache = {}
        engine._previewQueue = engine.owner.modes.map(m => m.id)
        if (isVideo) {
            // Own extraction Process (not the one regenerateFrom uses) — a
            // wallpaper commit calls both regenerateFrom (if dynamic) AND
            // generatePreviews back-to-back; sharing one Process's `running`/
            // `onDone` between them raced (the second call's running=true
            // was a no-op while the first was still mid-flight, silently
            // dropping whichever callback got overwritten).
            engine._extractFramePreview(wallpaperPath, framePath => {
                engine._previewWallpaperPath = framePath
                engine._runNextPreview()
            })
        } else {
            engine._previewWallpaperPath = wallpaperPath
            engine._runNextPreview()
        }
    }

    property string _previewWallpaperPath: ""
    readonly property string _previewVideoFramePath: `${Paths.cache}/quickshell-theme-preview-frame.png`
    Process { id: previewExtractFrameProc; property var onDone: null }

    function _extractFramePreview(videoPath, onDone) {
        if (!engine.ffmpegthumbnailerAvailable) return
        previewExtractFrameProc.onDone = onDone
        previewExtractFrameProc.command = ["ffmpegthumbnailer", "-i", videoPath, "-o", engine._previewVideoFramePath, "-s", "512"]
        previewExtractFrameProc.exited.connect(engine._onPreviewFrameExtracted)
        previewExtractFrameProc.running = true
    }

    function _onPreviewFrameExtracted(exitCode) {
        previewExtractFrameProc.exited.disconnect(engine._onPreviewFrameExtracted)
        if (exitCode === 0 && previewExtractFrameProc.onDone) previewExtractFrameProc.onDone(engine._previewVideoFramePath)
        previewExtractFrameProc.onDone = null
    }

    function _runNextPreview() {
        if (engine._previewQueue.length === 0) return
        const modeId = engine._previewQueue.shift()
        previewProc.pendingMode = modeId
        previewProc.command = ["matugen", "image", engine._previewWallpaperPath,
            "--type", modeId,
            "--mode", engine.owner.isLight ? "light" : "dark",
            "--source-color-index", "0",
            "--dry-run", "--quiet",
            "--json", "hex"]
        previewProc.running = true
    }
}
