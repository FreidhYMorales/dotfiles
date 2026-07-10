pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils"

Singleton {
    id: root

    // Fallback palette (Catppuccin-ish) — reemplazada cuando matugen corre.
    // Nota: propiedades que empiezan con "on" están reservadas en QML como signal
    // handlers, por eso usamos prefijo m3 en todo (igual que Caelestia).

    // Primary
    property color m3primary:                  "#cba6f7"
    property color m3onPrimary:                "#1e0043"
    property color m3primaryContainer:         "#3b0075"
    property color m3onPrimaryContainer:       "#e9ddff"

    // Secondary
    property color m3secondary:                "#cdd6f4"
    property color m3onSecondary:              "#1e2039"
    property color m3secondaryContainer:       "#30334f"
    property color m3onSecondaryContainer:     "#e8def8"

    // Tertiary
    property color m3tertiary:                 "#f38ba8"
    property color m3onTertiary:               "#4b2039"
    property color m3tertiaryContainer:        "#633751"
    property color m3onTertiaryContainer:      "#ffd8ee"

    // Surface / background
    property color m3background:               "#1e1e2e"
    property color m3onBackground:             "#cdd6f4"
    property color m3surface:                  "#1e1e2e"
    property color m3onSurface:                "#cdd6f4"
    property color m3surfaceDim:               "#181825"
    property color m3surfaceBright:            "#313244"
    property color m3surfaceContainerLowest:   "#11111b"
    property color m3surfaceContainerLow:      "#1e1e2e"
    property color m3surfaceContainer:         "#24273a"
    property color m3surfaceContainerHigh:     "#313244"
    property color m3surfaceContainerHighest:  "#45475a"
    property color m3onSurfaceVariant:         "#bac2de"
    property color m3outline:                  "#585b70"
    property color m3outlineVariant:           "#45475a"

    // Error
    property color m3error:                    "#f38ba8"
    property color m3onError:                  "#690005"
    property color m3errorContainer:           "#93000a"
    property color m3onErrorContainer:         "#ffdad6"

    // Inverse
    property color m3inverseSurface:           "#cdd6f4"
    property color m3inverseOnSurface:         "#322f35"
    property color m3inversePrimary:           "#7c3aed"

    // Scrim / shadow
    property color m3scrim:                    "#000000"
    property color m3shadow:                   "#000000"

    // Terminal palette (Catppuccin Mocha fallback)
    property color term0: "#1e1e2e"
    property color term1: "#f38ba8"
    property color term2: "#a6e3a1"
    property color term3: "#f9e2af"
    property color term4: "#89b4fa"
    property color term5: "#cba6f7"
    property color term6: "#89dceb"
    property color term7: "#bac2de"

    property string scheme: "dark"

    // Transparency settings (glassmorphism effect)
    readonly property QtObject transparency: QtObject {
        readonly property bool  enabled: true
        readonly property real  base:    0.85
    }

    // palette — named sub-object mirroring all m3* colors for dot-access syntax
    readonly property QtObject palette: QtObject {
        readonly property color m3primary:              root.m3primary
        readonly property color m3onPrimary:            root.m3onPrimary
        readonly property color m3primaryContainer:     root.m3primaryContainer
        readonly property color m3onPrimaryContainer:   root.m3onPrimaryContainer
        readonly property color m3secondary:            root.m3secondary
        readonly property color m3onSecondary:          root.m3onSecondary
        readonly property color m3secondaryContainer:   root.m3secondaryContainer
        readonly property color m3onSecondaryContainer: root.m3onSecondaryContainer
        readonly property color m3tertiary:             root.m3tertiary
        readonly property color m3onTertiary:           root.m3onTertiary
        readonly property color m3tertiaryContainer:    root.m3tertiaryContainer
        readonly property color m3onTertiaryContainer:  root.m3onTertiaryContainer
        readonly property color m3error:                root.m3error
        readonly property color m3onError:              root.m3onError
        readonly property color m3errorContainer:       root.m3errorContainer
        readonly property color m3onErrorContainer:     root.m3onErrorContainer
        readonly property color m3background:           root.m3background
        readonly property color m3onBackground:         root.m3onBackground
        readonly property color m3surface:              root.m3surface
        readonly property color m3onSurface:            root.m3onSurface
        readonly property color m3surfaceVariant:       root.m3surfaceContainerHigh
        readonly property color m3onSurfaceVariant:     root.m3onSurfaceVariant
        readonly property color m3surfaceContainer:     root.m3surfaceContainer
        readonly property color m3surfaceContainerLow:  root.m3surfaceContainerLow
        readonly property color m3surfaceContainerHigh: root.m3surfaceContainerHigh
        readonly property color m3surfaceContainerHighest: root.m3surfaceContainerHighest
        readonly property color m3outline:              root.m3outline
        readonly property color m3outlineVariant:       root.m3outlineVariant
        readonly property color m3inverseSurface:       root.m3inverseSurface
        readonly property color m3inverseOnSurface:     root.m3inverseOnSurface
        readonly property color m3inversePrimary:       root.m3inversePrimary
        readonly property color m3shadow:               root.m3shadow
        readonly property color m3scrim:                root.m3scrim
        // Terminal palette
        readonly property color term0: root.term0
        readonly property color term1: root.term1
        readonly property color term2: root.term2
        readonly property color term3: root.term3
        readonly property color term4: root.term4
        readonly property color term5: root.term5
        readonly property color term6: root.term6
        readonly property color term7: root.term7
    }

    // tPalette — semi-transparent variant for glassmorphism surfaces
    readonly property QtObject tPalette: QtObject {
        readonly property color m3primary:              Qt.alpha(root.m3primary, 0.85)
        readonly property color m3secondary:            Qt.alpha(root.m3secondary, 0.85)
        readonly property color m3tertiary:             Qt.alpha(root.m3tertiary, 0.85)
        readonly property color m3surface:              Qt.alpha(root.m3surface, 0.75)
        readonly property color m3surfaceContainer:     Qt.alpha(root.m3surfaceContainer, 0.85)
        readonly property color m3surfaceContainerHigh: Qt.alpha(root.m3surfaceContainerHigh, 0.80)
        readonly property color m3surfaceContainerHighest: Qt.alpha(root.m3surfaceContainerHighest, 0.80)
        readonly property color m3error:                Qt.alpha(root.m3error, 0.85)
        readonly property color m3background:           Qt.alpha(root.m3background, 0.90)
    }

    // layer() — lighten a color by depth steps for layered surfaces
    function layer(baseColor, depth) {
        if (depth === undefined) depth = 1
        return Qt.lighter(baseColor, 1.0 + depth * 0.06)
    }

    // mid() — flat RGB midpoint between two colors (e.g. a border that sits
    // tonally between a dark pill and the slightly-less-dark surface it's on)
    function mid(colorA, colorB) {
        return Qt.rgba((colorA.r + colorB.r) / 2, (colorA.g + colorB.g) / 2,
                        (colorA.b + colorB.b) / 2, 1)
    }

    // --- Theming modes (launcher's ">theme" picker) ---
    // The 9 real matugen `--type scheme-*` values, with friendly names.
    // "Dynamic" isn't a scheme type — it's the separate `dynamic` toggle
    // below (auto-regenerate colors whenever the wallpaper is committed).
    readonly property var modes: [
        { id: "scheme-tonal-spot",  name: "Default" },
        { id: "scheme-monochrome",  name: "Mono" },
        { id: "scheme-vibrant",     name: "Vibrant" },
        { id: "scheme-expressive",  name: "Expressive" },
        { id: "scheme-fidelity",    name: "Fidelity" },
        { id: "scheme-content",     name: "Content" },
        { id: "scheme-neutral",     name: "Neutral" },
        { id: "scheme-rainbow",     name: "Rainbow" },
        { id: "scheme-fruit-salad", name: "Fruit Salad" }
    ]

    property string currentMode: "scheme-content"
    property bool isLight: false
    // Auto-regenerate colors from the wallpaper on every wallpaper commit —
    // set directly (not through commit()), persists on change like the rest.
    property bool dynamic: false

    onDynamicChanged: root._persistTheme()

    // Committing a new mode always regenerates against the current wallpaper
    // (regardless of `dynamic`, which only governs auto-regen on *wallpaper*
    // commits — see Wallpapers.qml).
    function commit(modeId, light) {
        root.currentMode = modeId
        root.isLight = light
        root._persistTheme()
        root.regenerateFrom(Wallpapers.actualCurrent, Wallpapers.isVideoPath(Wallpapers.actualCurrent))
        // Keep every per-monitor override in the same scheme mode as the
        // global theme — otherwise a monitor's palette would silently stay
        // on whatever mode was active the last time IT was committed.
        for (const screenName in Wallpapers.perScreen)
            root.regeneratePaletteFor(screenName, Wallpapers.perScreen[screenName],
                Wallpapers.isVideoPath(Wallpapers.perScreen[screenName]))
    }

    // --- Per-monitor palettes (bar/panels only — see regeneratePaletteFor) ---
    // Keyed by ShellScreen.name. A screen with no entry here just follows the
    // global flat m3* properties/`palette` above (shared default, kept in
    // sync with kitty/Hyprland/btop/SDDM/etc via the real matugen pipeline).
    property var palettes: ({})

    // Resolves the palette a bar/panel widget on `screenName` should read
    // from — either its own override or the shared global `palette`. Every
    // property present on `palette` is also present here, so both branches
    // are safe to dot-access identically (Colours.paletteFor(s).m3primary).
    function paletteFor(screenName) {
        return root.palettes[screenName] ?? root.palette
    }

    function clearScreenPalettes() {
        root.palettes = {}
    }

    // Same field mapping as parse() below, but returned as a plain object
    // instead of mutated onto root.m3* — used for per-monitor palettes,
    // which must NEVER touch the globally-applied colors or external apps.
    //
    // Note: this reads matugen's own `--json hex` dump shape (used for
    // --dry-run calls), which nests each color as
    // { default: { color }, dark: { color }, light: { color } } — NOT the
    // { hex } shape that the real colors.json (written by our OWN
    // colors.json.template) uses in parse() below. "default" already
    // reflects whichever --mode light/dark was requested on the CLI, same
    // as the existing _runNextPreview swatch reader.
    function _extractPalette(data) {
        if (!data?.colors) return null
        const c = data.colors
        return {
            m3primary:                 c.primary?.default?.color                   ?? root.m3primary,
            m3onPrimary:               c.on_primary?.default?.color                ?? root.m3onPrimary,
            m3primaryContainer:        c.primary_container?.default?.color         ?? root.m3primaryContainer,
            m3onPrimaryContainer:      c.on_primary_container?.default?.color      ?? root.m3onPrimaryContainer,
            m3secondary:               c.secondary?.default?.color                 ?? root.m3secondary,
            m3onSecondary:             c.on_secondary?.default?.color              ?? root.m3onSecondary,
            m3secondaryContainer:      c.secondary_container?.default?.color       ?? root.m3secondaryContainer,
            m3onSecondaryContainer:    c.on_secondary_container?.default?.color    ?? root.m3onSecondaryContainer,
            m3tertiary:                c.tertiary?.default?.color                  ?? root.m3tertiary,
            m3onTertiary:              c.on_tertiary?.default?.color               ?? root.m3onTertiary,
            m3tertiaryContainer:       c.tertiary_container?.default?.color        ?? root.m3tertiaryContainer,
            m3onTertiaryContainer:     c.on_tertiary_container?.default?.color     ?? root.m3onTertiaryContainer,
            m3background:              c.background?.default?.color                ?? root.m3background,
            m3onBackground:            c.on_background?.default?.color             ?? root.m3onBackground,
            m3surface:                 c.surface?.default?.color                   ?? root.m3surface,
            m3onSurface:               c.on_surface?.default?.color                ?? root.m3onSurface,
            m3surfaceDim:              c.surface_dim?.default?.color               ?? root.m3surfaceDim,
            m3surfaceBright:           c.surface_bright?.default?.color            ?? root.m3surfaceBright,
            m3surfaceContainerLowest:  c.surface_container_lowest?.default?.color  ?? root.m3surfaceContainerLowest,
            m3surfaceContainerLow:     c.surface_container_low?.default?.color     ?? root.m3surfaceContainerLow,
            m3surfaceContainer:        c.surface_container?.default?.color         ?? root.m3surfaceContainer,
            m3surfaceContainerHigh:    c.surface_container_high?.default?.color    ?? root.m3surfaceContainerHigh,
            m3surfaceContainerHighest: c.surface_container_highest?.default?.color ?? root.m3surfaceContainerHighest,
            m3onSurfaceVariant:        c.on_surface_variant?.default?.color        ?? root.m3onSurfaceVariant,
            m3outline:                 c.outline?.default?.color                   ?? root.m3outline,
            m3outlineVariant:          c.outline_variant?.default?.color           ?? root.m3outlineVariant,
            m3error:                   c.error?.default?.color                     ?? root.m3error,
            m3onError:                 c.on_error?.default?.color                  ?? root.m3onError,
            m3errorContainer:          c.error_container?.default?.color           ?? root.m3errorContainer,
            m3onErrorContainer:        c.on_error_container?.default?.color        ?? root.m3onErrorContainer,
            m3inverseSurface:          c.inverse_surface?.default?.color           ?? root.m3inverseSurface,
            m3inverseOnSurface:        c.inverse_on_surface?.default?.color        ?? root.m3inverseOnSurface,
            m3inversePrimary:          c.inverse_primary?.default?.color           ?? root.m3inversePrimary,
            m3scrim:                   c.scrim?.default?.color                     ?? root.m3scrim,
            m3shadow:                  c.shadow?.default?.color                    ?? root.m3shadow
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
        if (!screenName || !path || !root.matugenAvailable) return
        root._screenPaletteQueue.push({ screenName: screenName, path: path, isVideo: isVideo })
        root._runNextScreenPalette()
    }

    function _runNextScreenPalette() {
        if (root._screenPaletteBusy || root._screenPaletteQueue.length === 0) return
        root._screenPaletteBusy = true
        const job = root._screenPaletteQueue.shift()
        if (job.isVideo) {
            root._extractFrameForScreenPalette(job.path, framePath => root._execScreenPalette(job.screenName, framePath))
        } else {
            root._execScreenPalette(job.screenName, job.path)
        }
    }

    function _extractFrameForScreenPalette(videoPath, onDone) {
        if (!root.ffmpegthumbnailerAvailable) {
            root._screenPaletteBusy = false
            root._runNextScreenPalette()
            return
        }
        screenPaletteExtractFrameProc.onDone = onDone
        screenPaletteExtractFrameProc.command = ["ffmpegthumbnailer", "-i", videoPath, "-o", root._screenPaletteFramePath, "-s", "512"]
        screenPaletteExtractFrameProc.exited.connect(root._onScreenPaletteFrameExtracted)
        screenPaletteExtractFrameProc.running = true
    }

    function _onScreenPaletteFrameExtracted(exitCode) {
        screenPaletteExtractFrameProc.exited.disconnect(root._onScreenPaletteFrameExtracted)
        if (exitCode === 0 && screenPaletteExtractFrameProc.onDone) {
            screenPaletteExtractFrameProc.onDone(root._screenPaletteFramePath)
        } else {
            root._screenPaletteBusy = false
            root._runNextScreenPalette()
        }
        screenPaletteExtractFrameProc.onDone = null
    }

    function _execScreenPalette(screenName, imagePath) {
        screenPaletteProc.pendingScreen = screenName
        screenPaletteProc.command = ["matugen", "image", imagePath,
            "--type", root.currentMode,
            "--mode", root.isLight ? "light" : "dark",
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
                    const parsed = root._extractPalette(data)
                    if (parsed) {
                        const next = Object.assign({}, root.palettes)
                        next[screenPaletteProc.pendingScreen] = parsed
                        root.palettes = next
                    }
                } catch (e) {
                    console.warn("Colours: failed to parse per-screen palette json for", screenPaletteProc.pendingScreen, e)
                }
                root._screenPaletteBusy = false
                root._runNextScreenPalette()
            }
        }
    }

    // --- matugen invocation (shared by Colours.commit + Wallpapers.commit) ---
    // matugen/ffmpegthumbnailer are optional at runtime — checked once at
    // startup so a missing binary just skips recoloring silently instead of
    // spamming Process errors on every commit.
    property bool matugenAvailable: false
    property bool ffmpegthumbnailerAvailable: false

    Process {
        id: checkMatugenProc
        command: ["which", "matugen"]
        onExited: exitCode => root.matugenAvailable = (exitCode === 0)
    }
    Process {
        id: checkFfmpegthumbnailerProc
        command: ["which", "ffmpegthumbnailer"]
        onExited: exitCode => root.ffmpegthumbnailerAvailable = (exitCode === 0)
    }

    readonly property string _videoFramePath: `${Paths.cache}/quickshell-wallpaper-frame.png`

    Process { id: extractFrameProc; property var onDone: null }
    Process {
        id: matugenProc
        onExited: exitCode => { if (exitCode === 0) postHookProc.running = true }
    }
    Process {
        id: postHookProc
        command: [Paths.home + "/.config/matugen/post-hook.sh"]
    }

    // path/isVideo describe the SOURCE (wallpaper) to derive colors from;
    // root.currentMode/isLight (already committed) pick the scheme type.
    function regenerateFrom(path, isVideo) {
        if (!path || !root.matugenAvailable) return
        if (isVideo) {
            root._extractFrame(path, root._runMatugen)
        } else {
            root._runMatugen(path)
        }
    }

    // Shared by regenerateFrom (single commit) and generatePreviews (batch
    // swatches) — both need the same "extract a frame first if it's a video"
    // step before matugen can read a source image.
    function _extractFrame(videoPath, onDone) {
        if (!root.ffmpegthumbnailerAvailable) return
        extractFrameProc.onDone = onDone
        extractFrameProc.command = ["ffmpegthumbnailer", "-i", videoPath, "-o", root._videoFramePath, "-s", "512"]
        extractFrameProc.exited.connect(root._onFrameExtracted)
        extractFrameProc.running = true
    }

    function _onFrameExtracted(exitCode) {
        extractFrameProc.exited.disconnect(root._onFrameExtracted)
        if (exitCode === 0 && extractFrameProc.onDone) extractFrameProc.onDone(root._videoFramePath)
        extractFrameProc.onDone = null
    }

    function _runMatugen(imagePath) {
        matugenProc.command = ["matugen", "image", imagePath,
            "--type", root.currentMode,
            "--mode", root.isLight ? "light" : "dark",
            "--source-color-index", "0",
            "--quiet"]
        matugenProc.running = true
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
                    const next = Object.assign({}, root.previewCache)
                    next[previewProc.pendingMode] = {
                        primary:   data.colors.primary.default.color,
                        secondary: data.colors.secondary.default.color,
                        tertiary:  data.colors.tertiary.default.color
                    }
                    root.previewCache = next
                } catch (e) {
                    console.warn("Colours: failed to parse preview json for", previewProc.pendingMode, e)
                }
                root._runNextPreview()
            }
        }
    }

    function generatePreviews(wallpaperPath, isVideo) {
        if (!wallpaperPath || !root.matugenAvailable) return
        root.previewCache = {}
        root._previewQueue = root.modes.map(m => m.id)
        if (isVideo) {
            // Own extraction Process (not the one regenerateFrom uses) — a
            // wallpaper commit calls both regenerateFrom (if dynamic) AND
            // generatePreviews back-to-back; sharing one Process's `running`/
            // `onDone` between them raced (the second call's running=true
            // was a no-op while the first was still mid-flight, silently
            // dropping whichever callback got overwritten).
            root._extractFramePreview(wallpaperPath, framePath => {
                root._previewWallpaperPath = framePath
                root._runNextPreview()
            })
        } else {
            root._previewWallpaperPath = wallpaperPath
            root._runNextPreview()
        }
    }

    property string _previewWallpaperPath: ""
    readonly property string _previewVideoFramePath: `${Paths.cache}/quickshell-theme-preview-frame.png`
    Process { id: previewExtractFrameProc; property var onDone: null }

    function _extractFramePreview(videoPath, onDone) {
        if (!root.ffmpegthumbnailerAvailable) return
        previewExtractFrameProc.onDone = onDone
        previewExtractFrameProc.command = ["ffmpegthumbnailer", "-i", videoPath, "-o", root._previewVideoFramePath, "-s", "512"]
        previewExtractFrameProc.exited.connect(root._onPreviewFrameExtracted)
        previewExtractFrameProc.running = true
    }

    function _onPreviewFrameExtracted(exitCode) {
        previewExtractFrameProc.exited.disconnect(root._onPreviewFrameExtracted)
        if (exitCode === 0 && previewExtractFrameProc.onDone) previewExtractFrameProc.onDone(root._previewVideoFramePath)
        previewExtractFrameProc.onDone = null
    }

    function _runNextPreview() {
        if (root._previewQueue.length === 0) return
        const modeId = root._previewQueue.shift()
        previewProc.pendingMode = modeId
        previewProc.command = ["matugen", "image", root._previewWallpaperPath,
            "--type", modeId,
            "--mode", root.isLight ? "light" : "dark",
            "--source-color-index", "0",
            "--dry-run", "--quiet",
            "--json", "hex"]
        previewProc.running = true
    }

    Process {
        id: mkThemeStateDirProc
        command: ["mkdir", "-p", Paths.appState]
    }

    FileView {
        id: themeStateFile
        path: Paths.themeStatePath
        watchChanges: false
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                if (saved.mode)                  root.currentMode = saved.mode
                if (saved.isLight !== undefined) root.isLight     = saved.isLight
                if (saved.dynamic !== undefined) root.dynamic     = saved.dynamic
            } catch (e) {
                console.warn("Colours: failed to parse theme state:", e)
            }
        }
    }

    function _persistTheme() {
        mkThemeStateDirProc.running = true
        themeStateFile.setText(JSON.stringify({ mode: root.currentMode, isLight: root.isLight, dynamic: root.dynamic }))
    }

    Component.onCompleted: {
        mkThemeStateDirProc.running = true
        checkMatugenProc.running = true
        checkFfmpegthumbnailerProc.running = true
    }

    FileView {
        id: colorsFile
        path: Paths.matugenColors
        watchChanges: true
        onTextChanged: root.parse(colorsFile.text())
        // watchChanges only fires fileChanged when the file is touched after
        // the initial load — it does NOT re-read text()/re-fire onTextChanged
        // on its own (confirmed empirically: a rewrite of an already-loaded
        // file only emits fileChanged, never textChanged, without an explicit
        // reload()). This is why matugen regenerating colors.json while the
        // shell is already running never re-colored anything until a full
        // restart — the wallpaper/theme commit worked, the file was correct,
        // but Colours never re-read it.
        onFileChanged: colorsFile.reload()
    }

    function parse(text) {
        if (!text || text.length === 0) return
        try {
            const data = JSON.parse(text)
            if (!data?.colors) return
            const c = data.colors

            root.scheme = data.scheme ?? "dark"

            if (c.primary)                   root.m3primary                  = c.primary.hex
            if (c.on_primary)                root.m3onPrimary                = c.on_primary.hex
            if (c.primary_container)         root.m3primaryContainer         = c.primary_container.hex
            if (c.on_primary_container)      root.m3onPrimaryContainer       = c.on_primary_container.hex

            if (c.secondary)                 root.m3secondary                = c.secondary.hex
            if (c.on_secondary)              root.m3onSecondary              = c.on_secondary.hex
            if (c.secondary_container)       root.m3secondaryContainer       = c.secondary_container.hex
            if (c.on_secondary_container)    root.m3onSecondaryContainer     = c.on_secondary_container.hex

            if (c.tertiary)                  root.m3tertiary                 = c.tertiary.hex
            if (c.on_tertiary)               root.m3onTertiary               = c.on_tertiary.hex
            if (c.tertiary_container)        root.m3tertiaryContainer        = c.tertiary_container.hex
            if (c.on_tertiary_container)     root.m3onTertiaryContainer      = c.on_tertiary_container.hex

            if (c.background)                root.m3background               = c.background.hex
            if (c.on_background)             root.m3onBackground             = c.on_background.hex
            if (c.surface)                   root.m3surface                  = c.surface.hex
            if (c.on_surface)                root.m3onSurface                = c.on_surface.hex
            if (c.surface_dim)               root.m3surfaceDim               = c.surface_dim.hex
            if (c.surface_bright)            root.m3surfaceBright            = c.surface_bright.hex
            if (c.surface_container_lowest)  root.m3surfaceContainerLowest   = c.surface_container_lowest.hex
            if (c.surface_container_low)     root.m3surfaceContainerLow      = c.surface_container_low.hex
            if (c.surface_container)         root.m3surfaceContainer         = c.surface_container.hex
            if (c.surface_container_high)    root.m3surfaceContainerHigh     = c.surface_container_high.hex
            if (c.surface_container_highest) root.m3surfaceContainerHighest  = c.surface_container_highest.hex
            if (c.on_surface_variant)        root.m3onSurfaceVariant         = c.on_surface_variant.hex
            if (c.outline)                   root.m3outline                  = c.outline.hex
            if (c.outline_variant)           root.m3outlineVariant           = c.outline_variant.hex

            if (c.error)                     root.m3error                    = c.error.hex
            if (c.on_error)                  root.m3onError                  = c.on_error.hex
            if (c.error_container)           root.m3errorContainer           = c.error_container.hex
            if (c.on_error_container)        root.m3onErrorContainer         = c.on_error_container.hex

            if (c.inverse_surface)           root.m3inverseSurface           = c.inverse_surface.hex
            if (c.inverse_on_surface)        root.m3inverseOnSurface         = c.inverse_on_surface.hex
            if (c.inverse_primary)           root.m3inversePrimary           = c.inverse_primary.hex

            if (c.scrim)                     root.m3scrim                    = c.scrim.hex
            if (c.shadow)                    root.m3shadow                   = c.shadow.hex
        } catch (e) {
            console.warn("Colours: failed to parse colors.json:", e)
        }
    }
}
