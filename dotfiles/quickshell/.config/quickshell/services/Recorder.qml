pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils"

// Screen recording via gpu-screen-recorder (AUR, not yet installed on this
// system — auto-detects GPU vendor per-machine: NVENC on the NVIDIA desktop,
// VAAPI on the Intel-only Thinkpad). No wf-recorder: gpu-screen-recorder
// picks the right encoder without per-machine config.
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
// Stopping requires SIGINT specifically (gpu-screen-recorder's documented
// "Ctrl+C: stop and save recording" — that's what triggers muxing/finalizing
// the mp4). Never toggle `recorderProc.running = false`: that would hit
// Quickshell's default process termination (SIGTERM/SIGKILL), leaving a
// corrupt, unmuxed file. recording only flips to false in onExited, once
// gpu-screen-recorder has actually finished writing the file.
Singleton {
    id: root

    property bool   recording:      false
    property string mode:           "screen"  // "screen" | "region" | "window" — display only
    property int    elapsedSeconds: 0
    property string lastOutputPath: ""

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
        recorderProc.command = ["gpu-screen-recorder", ...extraArgs,
                                 "-a", "default_output", "-c", "mp4", "-o", root.lastOutputPath]
        recorderProc.running = true
        root.recording        = true
    }

    function startScreen() {
        if (root.recording) return
        root._startRecorder(["-w", "screen"], "screen")
    }

    function startRegion() {
        if (root.recording) return
        slurpRegionProc._buf = ""
        slurpRegionProc.running = false
        slurpRegionProc.running = true
    }

    function startWindow() {
        if (root.recording) return
        hyprctlClientsProc._buf = ""
        hyprctlClientsProc.running = false
        hyprctlClientsProc.running = true
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
    Process {
        id: slurpRegionProc
        running: false
        property string _buf: ""
        command: ["slurp"]
        stdout: SplitParser {
            onRead: line => slurpRegionProc._buf += line + "\n"
        }
        onExited: (exitCode, exitStatus) => {
            const raw = slurpRegionProc._buf.trim()
            slurpRegionProc._buf = ""
            if (exitCode === 0 && raw) {
                root._startRecorder(["-w", "region", "-region", root._slurpToRegionArg(raw)], "region")
            } else {
                console.warn("Recorder: region selection cancelled or failed")
            }
        }
    }

    // --- window mode: hyprctl clients -j -> candidate rects -> slurp -r ---
    Process {
        id: hyprctlClientsProc
        running: false
        property string _buf: ""
        command: ["hyprctl", "clients", "-j"]
        stdout: SplitParser {
            onRead: line => hyprctlClientsProc._buf += line + "\n"
        }
        onExited: (exitCode, exitStatus) => {
            const buf = hyprctlClientsProc._buf
            hyprctlClientsProc._buf = ""
            if (exitCode !== 0) {
                console.warn("Recorder: hyprctl clients failed, exit code", exitCode)
                return
            }
            try {
                const clients = JSON.parse(buf)
                const lines = []
                for (let i = 0; i < clients.length; i++) {
                    const c = clients[i]
                    if (c.mapped === false || c.hidden === true) continue
                    if (!c.size || !c.at) continue
                    const [w, h] = c.size
                    const [x, y] = c.at
                    if (w <= 0 || h <= 0) continue
                    const label = (c.title || c.class || "window").replace(/\n/g, " ")
                    lines.push(`${x},${y} ${w}x${h} ${label}`)
                }
                if (lines.length === 0) {
                    console.warn("Recorder: no windows available for window-mode selection")
                    return
                }
                root._pickWindowRegion(lines)
            } catch (e) {
                console.warn("Recorder: failed to parse hyprctl clients output:", e)
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
        slurpWindowProc._buf = ""
        slurpWindowProc.stdinEnabled = true
        slurpWindowProc.running = false
        slurpWindowProc.running = true
        slurpWindowProc.write(lines.join("\n") + "\n")
        slurpWindowProc.stdinEnabled = false  // closes the write channel -> EOF, slurp proceeds
    }

    Process {
        id: slurpWindowProc
        running: false
        property string _buf: ""
        command: ["slurp", "-r"]
        stdout: SplitParser {
            onRead: line => slurpWindowProc._buf += line + "\n"
        }
        onExited: (exitCode, exitStatus) => {
            const raw = slurpWindowProc._buf.trim()
            slurpWindowProc._buf = ""
            if (exitCode === 0 && raw) {
                root._startRecorder(["-w", "region", "-region", root._slurpToRegionArg(raw)], "window")
            } else {
                console.warn("Recorder: window selection cancelled or failed")
            }
        }
    }

    // --- ensure the output folder exists (no persistence otherwise — same
    // mkdir-bootstrap pattern as IdleManager.qml, just without a state file) ---
    Process {
        id: mkRecordingsDirProc
        command: ["mkdir", "-p", Paths.recordingsDir]
    }

    Component.onCompleted: mkRecordingsDirProc.running = true
}
