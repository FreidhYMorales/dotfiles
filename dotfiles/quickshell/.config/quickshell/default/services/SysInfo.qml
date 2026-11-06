pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int  cpu:     0
    property int  ram:     0
    property int  gpu:     0
    property int  gpuTemp: 0
    property int  igpu:    0
    property bool hasIgpu: false
    property int  npu:     0
    property bool hasNpu:  false
    property int  disk:    0
    property bool hasGpu:  false

    property string _igpuMode: ""
    property string _igpuPath: ""
    property real   _lastIgpuIdle: -1
    property real   _lastIgpuTime: 0

    property string _npuPath: ""
    property real   _lastNpuBusy: -1
    property real   _lastNpuTime: 0

    property string osName:   "Arch Linux"
    property string wmName:   "Hyprland"
    property string userName: ""
    property string uptime:   ""
    property int    cpuTemp:  0

    property real _lastIdle:  0
    property real _lastTotal: 0
    property real _memTotal:  0
    property real _memFree:   0

    // Detect nvidia-smi once at startup; enables GPU polling only when available
    Component.onCompleted: {
        gpuCheckProc.running  = true
        igpuCheckProc.running = true
        npuCheckProc.running  = true
        const u = Quickshell.env("USER")
        if (u) root.userName = u
    }

    Process {
        id: gpuCheckProc
        // -L actually queries the driver — command -v only checks the binary
        // exists, which is true even on systems with no NVIDIA hardware at
        // all (leftover nvidia-utils package), giving a false positive.
        command: ["bash", "-c", "nvidia-smi -L >/dev/null 2>&1 && echo 1 || echo 0"]
        stdout: SplitParser {
            onRead: line => { root.hasGpu = line.trim() === "1" }
        }
    }

    // Detect the Intel iGPU driver once at startup — this repo runs on both
    // i915 machines (Dell, HD 520) and xe machines (ThinkPad, Lunar Lake Arc)
    // so both are checked. Matches strictly on the driver symlink name (not
    // just file presence) since amdgpu also exposes a "gpu_busy_percent"
    // file with the same name, which would misattribute a discrete AMD GPU's
    // usage as the iGPU's on the Dell's hybrid Intel+AMD setup.
    Process {
        id: igpuCheckProc
        command: ["bash", "-c",
            "for c in /sys/class/drm/card*/device; do " +
            "drv=$(basename $(readlink -f $c/driver 2>/dev/null) 2>/dev/null); " +
            "if [ \"$drv\" = i915 ] && [ -f $c/gpu_busy_percent ]; then echo i915:$c/gpu_busy_percent; exit 0; fi; " +
            "if [ \"$drv\" = xe ] && [ -f $c/tile0/gt0/gtidle/idle_residency_ms ]; then echo xe:$c/tile0/gt0/gtidle/idle_residency_ms; exit 0; fi; " +
            "done; echo none"
        ]
        stdout: SplitParser {
            onRead: line => {
                const s = line.trim()
                const idx = s.indexOf(":")
                if (idx < 0) { root.hasIgpu = false; return }
                root._igpuMode = s.slice(0, idx)
                root._igpuPath = s.slice(idx + 1)
                root.hasIgpu   = true
            }
        }
    }

    // Detect the Intel NPU driver once at startup — exposed as an accel(4)
    // class device (/sys/class/accel/accelN) when intel-npu-driver-bin is
    // installed and the hardware is present (Core Ultra 200V "Lunar Lake"+).
    // npu_busy_time_us is cumulative, like the xe iGPU's idle_residency_ms,
    // so it needs the same delta-over-wall-time approach in _parseNpu below.
    Process {
        id: npuCheckProc
        command: ["bash", "-c",
            "for f in /sys/class/accel/accel*/device/npu_busy_time_us; do " +
            "[ -f \"$f\" ] && echo \"$f\" && exit 0; done; echo none"
        ]
        stdout: SplitParser {
            onRead: line => {
                const s = line.trim()
                if (s === "none" || !s) { root.hasNpu = false; return }
                root._npuPath = s
                root.hasNpu   = true
            }
        }
    }

    // CPU/RAM used to be a `grep /proc/stat`/`grep /proc/meminfo` Process
    // spawned every 2s, forever — a fork+exec just to read two small files
    // Qt can already read in-process. FileView.reload() below does the same
    // job with zero process spawns.
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload()
            memFile.reload()
            if (root.hasGpu)  gpuProc.running = true
            if (root.hasIgpu) igpuFile.reload()
            if (root.hasNpu)  npuFile.reload()
        }
    }

    // Disk % and CPU temp don't need sub-2s freshness for a dashboard
    // display — sharing the slow timer with uptime cuts their Process
    // forks from every 2s down to every 30s.
    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            uptimeProc.running  = false
            uptimeProc.running  = true
            diskProc.running    = true
            cpuTempProc.running = false
            cpuTempProc.running = true
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        watchChanges: false
        onTextChanged: root._parseCpu(text())
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        watchChanges: false
        onTextChanged: root._parseRam(text())
    }

    // Path is set dynamically by igpuCheckProc above — i915 reports a ready-
    // made busy percentage, xe only exposes cumulative idle time so it needs
    // the same delta-over-wall-time approach as _parseCpu below.
    FileView {
        id: igpuFile
        path: root._igpuPath
        watchChanges: false
        onTextChanged: root._parseIgpu(text())
    }

    FileView {
        id: npuFile
        path: root._npuPath
        watchChanges: false
        onTextChanged: root._parseNpu(text())
    }

    function _parseCpu(text) {
        const line = text.split("\n").find(l => l.startsWith("cpu "))
        if (!line) return
        const p = line.trim().split(/\s+/)
        const idle  = +p[4] + +p[5]
        const total = p.slice(1).reduce((s, v) => s + +v, 0)
        if (root._lastTotal > 0) {
            const dt = total - root._lastTotal
            const di = idle  - root._lastIdle
            if (dt > 0)
                root.cpu = Math.max(0, Math.min(100, Math.round((1 - di / dt) * 100)))
        }
        root._lastIdle  = idle
        root._lastTotal = total
    }

    function _parseRam(text) {
        const totalMatch = text.match(/^MemTotal:\s+(\d+)/m)
        const availMatch = text.match(/^MemAvailable:\s+(\d+)/m)
        if (totalMatch) root._memTotal = +totalMatch[1]
        if (availMatch) root._memFree  = +availMatch[1]
        if (root._memTotal > 0)
            root.ram = Math.round((1 - root._memFree / root._memTotal) * 100)
    }

    function _parseIgpu(text) {
        if (root._igpuMode === "i915") {
            const v = parseInt(text.trim())
            if (!isNaN(v)) root.igpu = Math.max(0, Math.min(100, v))
            return
        }
        if (root._igpuMode === "xe") {
            const idle = parseFloat(text.trim())
            if (isNaN(idle)) return
            const now = Date.now()
            if (root._lastIgpuIdle >= 0) {
                const dIdle = idle - root._lastIgpuIdle
                const dTime = now - root._lastIgpuTime
                if (dTime > 0)
                    root.igpu = Math.max(0, Math.min(100, Math.round((1 - dIdle / dTime) * 100)))
            }
            root._lastIgpuIdle = idle
            root._lastIgpuTime = now
        }
    }

    // npu_busy_time_us counts up while the NPU is active — the opposite
    // sense of the xe iGPU's idle_residency_ms — so the ratio isn't inverted.
    function _parseNpu(text) {
        const busyUs = parseFloat(text.trim())
        if (isNaN(busyUs)) return
        const now = Date.now()
        if (root._lastNpuBusy >= 0) {
            const dBusyMs = (busyUs - root._lastNpuBusy) / 1000
            const dTimeMs = now - root._lastNpuTime
            if (dTimeMs > 0)
                root.npu = Math.max(0, Math.min(100, Math.round(dBusyMs / dTimeMs * 100)))
        }
        root._lastNpuBusy = busyUs
        root._lastNpuTime = now
    }

    Process {
        id: diskProc
        command: ["df", "/", "--output=pcent"]
        stdout: SplitParser {
            onRead: line => {
                const val = parseInt(line.trim().replace("%", ""))
                if (!isNaN(val)) root.disk = val
            }
        }
    }

    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(",")
                if (parts.length < 2) return
                const util = parseInt(parts[0].trim())
                const temp = parseInt(parts[1].trim())
                if (!isNaN(util)) root.gpu     = util
                if (!isNaN(temp)) root.gpuTemp = temp
            }
        }
    }

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        stdout: SplitParser {
            onRead: line => {
                const v = line.trim().replace(/^up /, "")
                if (v) root.uptime = v
            }
        }
    }

    Process {
        id: cpuTempProc
        command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1"]
        stdout: SplitParser {
            onRead: line => {
                const v = parseInt(line.trim())
                if (!isNaN(v) && v > 0) root.cpuTemp = Math.round(v / 1000)
            }
        }
    }
}
