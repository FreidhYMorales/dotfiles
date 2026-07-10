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
    property int  disk:    0
    property bool hasGpu:  false

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
        gpuCheckProc.running = true
        const u = Quickshell.env("USER")
        if (u) root.userName = u
    }

    Process {
        id: gpuCheckProc
        command: ["bash", "-c", "command -v nvidia-smi >/dev/null 2>&1 && echo 1 || echo 0"]
        stdout: SplitParser {
            onRead: line => { root.hasGpu = line.trim() === "1" }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running      = true
            ramProc.running      = true
            diskProc.running     = true
            cpuTempProc.running  = false
            cpuTempProc.running  = true
            if (root.hasGpu) gpuProc.running = true
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            uptimeProc.running  = false
            uptimeProc.running  = true
        }
    }

    Process {
        id: cpuProc
        command: ["grep", "^cpu ", "/proc/stat"]
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim().split(/\s+/)
                if (p[0] !== "cpu") return
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
        }
    }

    Process {
        id: ramProc
        command: ["grep", "-E", "^MemTotal:|^MemAvailable:", "/proc/meminfo"]
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim().split(/\s+/)
                if (p[0] === "MemTotal:")     root._memTotal = +p[1]
                if (p[0] === "MemAvailable:") root._memFree  = +p[1]
                if (root._memTotal > 0)
                    root.ram = Math.round((1 - root._memFree / root._memTotal) * 100)
            }
        }
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
