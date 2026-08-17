pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils"

// Screen recording via gpu-screen-recorder (AUR) — auto-detects GPU vendor
// per-machine: NVENC on an NVIDIA machine, VAAPI on Intel/AMD elsewhere
// (confirmed live on this ThinkPad's Arc iGPU, h264 via VAAPI, no extra
// config). No wf-recorder: gpu-screen-recorder picks the right encoder
// without per-machine config.
//
// "Window mode" is NOT a live follow of a window — Wayland has no portable
// -w window/-w focused equivalent (those are X11-only in gpu-screen-recorder;
// the only Wayland-native path is -w portal, which has known bugs on
// Hyprland). Instead it's a one-shot static region: hyprctl clients -j lists
// window bounding boxes, slurp -r restricts the interactive pick to those
// boxes, and the chosen box is recorded exactly like -w region. If the
// window moves during recording, the capture does not follow it — an
// accepted trade-off for reusing the reliable region path.
//
// hyprctl clients -j returns windows from EVERY workspace, not just the
// visible one — and Hyprland lays out each workspace from the same origin,
// so a window on a hidden workspace can report the exact same `at`/`size`
// as one you can actually see. Fed unfiltered into slurp -r, that gives it
// multiple exactly-overlapping candidates for the same screen spot, which
// it can't visually disambiguate — confirmed live (two windows on different
// workspaces, identical at:[12,66] size:[1576,822]). Filtered down to only
// the focused monitor's active workspace (hyprctl activeworkspace -j) before
// listing clients, so every candidate slurp -r sees is a distinct, actually
// visible window.
//
// Stopping requires SIGINT specifically (gpu-screen-recorder's documented
// "Ctrl+C: stop and save recording" — that's what triggers muxing/finalizing
// the mp4). Never toggle `recorderProc.running = false`: that would hit
// Quickshell's default process termination (SIGTERM/SIGKILL), leaving a
// corrupt, unmuxed file. recording only flips to false in onExited, once
// gpu-screen-recorder has actually finished writing the file.
Singleton {
    id: root

    property bool   recording:      false
    // "screen" | "region" | "window" — both the preferred mode for the next
    // recording (set from the dashboard's RecorderSection) and, once a
    // recording is running, which mode it actually started in.
    property string mode:           "screen"
    property bool   audioEnabled:   true
    property int    elapsedSeconds: 0
    property string lastOutputPath: ""
    property int    _activeWorkspaceId: -1

    // Changing the mode mid-recording would be misleading (it wouldn't
    // affect the process already running) — only settable while idle.
    function setMode(m) {
        if (root.recording) return
        if (m === "screen" || m === "region" || m === "window") root.mode = m
    }

    // Dispatches to whichever start* the current mode calls for — the single
    // entry point the bar widget's left click uses now that mode selection
    // lives in the dashboard instead of a right-click OSD.
    function start() {
        if (root.recording) return
        if (root.mode === "region")      root.startRegion()
        else if (root.mode === "window") root.startWindow()
        else                              root.startScreen()
    }

    Timer {
        interval: 1000
        running:  root.recording
        repeat:   true
        onTriggered: root.elapsedSeconds++
    }

    function _outputPath() {
        const now = new Date()
        const pad = n => String(n).padStart(2, "0")
        const stamp = `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}-`
                    + `${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`
        return `${Paths.recordingsDir}/recording-${stamp}.mp4`
    }

    // slurp's default output format is "X,Y WxH" (e.g. "100,200 800x600") —
    // gpu-screen-recorder's -region wants "WxH+X+Y". Confirmed from slurp(1):
    // default format is "%x,%y %wx%h\n"; we never pass -f so no label suffix
    // is ever present to strip.
    function _slurpToRegionArg(raw) {
        const parts = raw.trim().split(" ")
        const [x, y] = parts[0].split(",")
        const [w, h] = parts[1].split("x")
        return `${w}x${h}+${x}+${y}`
    }

    function _startRecorder(extraArgs, modeName) {
        root.mode           = modeName
        root.lastOutputPath = root._outputPath()
        const audioArgs = root.audioEnabled ? ["-a", "default_output"] : []
        recorderProc.command = ["gpu-screen-recorder", ...extraArgs, ...audioArgs,
                                 "-c", "mp4", "-o", root.lastOutputPath]
        recorderProc.running = true
        root.recording        = true
    }

    function startScreen() {
        if (root.recording) return
        root._startRecorder(["-w", "screen"], "screen")
    }

    function startRegion() {
        if (root.recording) return
        Quickshell.execDetached(["notify-send", "-a", "Quickshell", "-t", "3000",
            "Select a region to record", "Drag with your mouse — Esc to cancel"])
        slurpRegionProc.running = false
        slurpRegionProc.running = true
    }

    function startWindow() {
        if (root.recording) return
        Quickshell.execDetached(["notify-send", "-a", "Quickshell", "-t", "3000",
            "Select a window to record", "Click a window — Esc to cancel"])
        activeWorkspaceProc.running = false
        activeWorkspaceProc.running = true
    }

    function stop() {
        if (!root.recording) return
        recorderProc.signal(2)  // SIGINT — see file header, must not use running=false
    }

    // --- recording process ---
    Process {
        id: recorderProc
        running: false
        onExited: (exitCode, exitStatus) => {
            root.recording      = false
            root.elapsedSeconds = 0
            if (exitCode === 0) {
                Quickshell.execDetached(["notify-send", "-a", "Quickshell",
                    "Recording saved", root.lastOutputPath])
            } else {
                Quickshell.execDetached(["notify-send", "-a", "Quickshell", "-u", "critical",
                    "Recording failed", `gpu-screen-recorder exited with code ${exitCode}`])
            }
        }
    }

    // --- region mode: plain interactive slurp ---
    //
    // StdioCollector, not SplitParser + manual buffering: reading the buffer
    // from onExited raced the last chunk of stdout still arriving — slurp's
    // single line of output could still be in flight when onExited fired,
    // silently dropping the selection (looked like clicking "region" just
    // did nothing). Same race Colours.qml hit with matugen's larger preview
    // JSON. onStreamFinished only fires once the full stream is captured.
    //
    // Wrapped in `script -qec ... /dev/null` to allocate a pseudo-TTY —
    // confirmed via `man slurp`: "If the standard input is not a TTY [...]
    // slurp will read a list of predefined rectangles" instead of showing
    // the interactive drag-to-select overlay. A Quickshell Process's stdin
    // is never a real TTY, so plain `slurp` here silently fell into
    // list-mode and sat there with no overlay and no rectangles on stdin —
    // confirmed empirically: `hyprctl layers` showed no "selection" overlay
    // layer at all while it was running unwrapped, and did show one once
    // wrapped. `-r` mode (window, below) is unaffected — it already wants
    // stdin-list behavior regardless of TTY, that's its whole purpose.
    Process {
        id: slurpRegionProc
        running: false
        command: ["script", "-qec", "slurp", "/dev/null"]
        stdout: StdioCollector {
            id: slurpRegionStdout
            onStreamFinished: {
                const raw = slurpRegionStdout.text.trim()
                if (raw) {
                    root._startRecorder(["-w", "region", "-region", root._slurpToRegionArg(raw)], "region")
                } else {
                    console.warn("Recorder: region selection cancelled or failed")
                    Quickshell.execDetached(["notify-send", "-a", "Quickshell",
                        "Region selection cancelled", "No recording was started"])
                }
            }
        }
    }

    // --- window mode: active workspace -> hyprctl clients -j (filtered) ->
    // candidate rects -> slurp -r ---
    Process {
        id: activeWorkspaceProc
        running: false
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceStdout
            onStreamFinished: {
                try {
                    root._activeWorkspaceId = JSON.parse(activeWorkspaceStdout.text).id
                } catch (e) {
                    console.warn("Recorder: failed to parse hyprctl activeworkspace output:", e)
                    root._activeWorkspaceId = -1
                }
                hyprctlClientsProc.running = false
                hyprctlClientsProc.running = true
            }
        }
    }

    Process {
        id: hyprctlClientsProc
        running: false
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: hyprctlClientsStdout
            onStreamFinished: {
                try {
                    const clients = JSON.parse(hyprctlClientsStdout.text)
                    const lines = []
                    for (let i = 0; i < clients.length; i++) {
                        const c = clients[i]
                        if (c.mapped === false || c.hidden === true) continue
                        if (!c.size || !c.at) continue
                        if (!c.workspace || c.workspace.id !== root._activeWorkspaceId) continue
                        const [w, h] = c.size
                        const [x, y] = c.at
                        if (w <= 0 || h <= 0) continue
                        const label = (c.title || c.class || "window").replace(/\n/g, " ")
                        lines.push(`${x},${y} ${w}x${h} ${label}`)
                    }
                    if (lines.length === 0) {
                        console.warn("Recorder: no windows available for window-mode selection")
                        Quickshell.execDetached(["notify-send", "-a", "Quickshell", "-u", "critical",
                            "Window recording failed", "No windows available to pick from"])
                        return
                    }
                    root._pickWindowRegion(lines)
                } catch (e) {
                    console.warn("Recorder: failed to parse hyprctl clients output:", e)
                    Quickshell.execDetached(["notify-send", "-a", "Quickshell", "-u", "critical",
                        "Window recording failed", "Could not read window list"])
                }
            }
        }
    }

    // slurp(1): "If standard input is not a TTY or the -r option is used,
    // slurp will read a list of predefined rectangles [...] Each line must
    // be in the form '<x>,<y> <width>x<height> [label]'" — read from stdin.
    // Verified locally via `man slurp` (zcat /usr/share/man/man1/slurp.1.gz)
    // on this machine, not just inferred: -r takes no argument, the
    // candidate list is fed on stdin in slurp's own output format.
    function _pickWindowRegion(lines) {
        slurpWindowProc.stdinEnabled = true
        slurpWindowProc.running = false
        slurpWindowProc.running = true
        slurpWindowProc.write(lines.join("\n") + "\n")
        slurpWindowProc.stdinEnabled = false  // closes the write channel -> EOF, slurp proceeds
    }

    Process {
        id: slurpWindowProc
        running: false
        command: ["slurp", "-r"]
        stdout: StdioCollector {
            id: slurpWindowStdout
            onStreamFinished: {
                const raw = slurpWindowStdout.text.trim()
                if (raw) {
                    root._startRecorder(["-w", "region", "-region", root._slurpToRegionArg(raw)], "window")
                } else {
                    console.warn("Recorder: window selection cancelled or failed")
                    Quickshell.execDetached(["notify-send", "-a", "Quickshell",
                        "Window selection cancelled", "No recording was started"])
                }
            }
        }
    }

    // --- ensure the output folder exists ---
    Process {
        id: mkRecordingsDirProc
        command: ["mkdir", "-p", Paths.recordingsDir]
    }

    Component.onCompleted: mkRecordingsDirProc.running = true

    // --- persistence (~/.local/state/quickshell/recorder.json) — mode +
    // audioEnabled only, same restored-gate pattern as IdleManager.qml so a
    // fresh process doesn't briefly overwrite the saved file with its
    // hardcoded defaults before the FileView finishes loading. ---
    property bool _restored: false

    onModeChanged:         if (_restored) _persist()
    onAudioEnabledChanged: if (_restored) _persist()

    Process {
        id: mkRecorderStateDirProc
        command: ["mkdir", "-p", Paths.appState]
    }

    FileView {
        id: recorderStateFile
        path: Paths.recorderStatePath
        watchChanges: false
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                if (saved.mode !== undefined)         root.mode         = saved.mode
                if (saved.audioEnabled !== undefined) root.audioEnabled = saved.audioEnabled
            } catch (e) {
                console.warn("Recorder: failed to parse recorder state:", e)
            }
            root._restored = true
        }
        onLoadFailed: root._restored = true
    }

    function _persist() {
        mkRecorderStateDirProc.running = true
        recorderStateFile.setText(JSON.stringify({
            mode:         root.mode,
            audioEnabled: root.audioEnabled
        }))
    }
}
