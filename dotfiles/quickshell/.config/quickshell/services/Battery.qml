pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int    percentage: 100
    property bool   charging:   false
    property int    health:     100
    property string timeStr:    "—"

    property string _batDev:  "BAT0"
    readonly property string _batPath: "/sys/class/power_supply/" + _batDev

    Timer {
        interval: 30000
        running:  true
        repeat:   true
        onTriggered: {
            capProc.running    = true
            statusProc.running = true
            timeProc.running   = true
        }
    }

    Component.onCompleted: batDiscoveryProc.running = true

    // Discovers the battery device name once; triggers initial reads when done
    Process {
        id: batDiscoveryProc
        command: ["bash", "-c", "set -- /sys/class/power_supply/BAT*/; [ -e \"$1\" ] && basename \"$1\" || echo BAT0"]
        stdout: SplitParser {
            onRead: line => {
                const d = line.trim()
                if (d) root._batDev = d
            }
        }
        onRunningChanged: {
            if (running) return
            capProc.running    = true
            statusProc.running = true
            timeProc.running   = true
            healthProc.running = true
        }
    }

    // Watch udev power_supply events — fires immediately on charger connect/disconnect
    Process {
        running: true
        command: ["udevadm", "monitor", "--subsystem-match=power_supply", "--udev"]
        stdout: SplitParser {
            onRead: _ => {
                capProc.running    = true
                statusProc.running = true
                timeProc.running   = true
            }
        }
    }

    Process {
        id: capProc
        command: ["cat", root._batPath + "/capacity"]
        stdout: SplitParser {
            onRead: line => {
                const val = parseInt(line.trim())
                if (!isNaN(val)) root.percentage = val
            }
        }
    }

    Process {
        id: statusProc
        command: ["cat", root._batPath + "/status"]
        stdout: SplitParser {
            onRead: line => {
                const s = line.trim()
                root.charging = (s === "Charging" || s === "Full")
            }
        }
    }

    // Reads energy_full/energy_full_design; falls back to charge_full/charge_full_design.
    Process {
        id: healthProc
        command: [
            "bash", "-c",
            "d=" + root._batPath + ";" +
            "a=$(cat $d/energy_full 2>/dev/null || cat $d/charge_full 2>/dev/null || echo 0);" +
            "b=$(cat $d/energy_full_design 2>/dev/null || cat $d/charge_full_design 2>/dev/null || echo 0);" +
            "echo $a $b"
        ]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(/\s+/)
                if (parts.length < 2) return
                const full   = parseFloat(parts[0])
                const design = parseFloat(parts[1])
                if (full > 0 && design > 0)
                    root.health = Math.round((full / design) * 100)
            }
        }
    }

    // Outputs: "<status> <energy_now> <energy_full> <power_now>" for time estimation.
    // Falls back to charge_now/charge_full/current_now when energy_* are unavailable.
    Process {
        id: timeProc
        command: [
            "bash", "-c",
            "d=" + root._batPath + ";" +
            "s=$(cat $d/status 2>/dev/null || echo Unknown);" +
            "p=$(cat $d/power_now 2>/dev/null || cat $d/current_now 2>/dev/null || echo 0);" +
            "n=$(cat $d/energy_now 2>/dev/null || cat $d/charge_now 2>/dev/null || echo 0);" +
            "f=$(cat $d/energy_full 2>/dev/null || cat $d/charge_full 2>/dev/null || echo 0);" +
            "echo $s $n $f $p"
        ]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(/\s+/)
                if (parts.length < 4) { root.timeStr = "—"; return }

                const status = parts[0]
                const now    = parseFloat(parts[1])
                const full   = parseFloat(parts[2])
                const pow    = parseFloat(parts[3])

                if (status === "Full")  { root.timeStr = "Full";   return }
                if (status === "Unknown" || pow <= 0) { root.timeStr = "—"; return }

                let hours, suffix
                if (status === "Discharging") {
                    hours  = now / pow
                    suffix = "remaining"
                } else {
                    hours  = (full - now) / pow
                    suffix = "to full"
                }

                if (hours <= 0 || !isFinite(hours)) { root.timeStr = "—"; return }

                const h = Math.floor(hours)
                const m = Math.round((hours - h) * 60)
                const mClamped = m >= 60 ? 59 : m
                root.timeStr = (h > 0 ? h + "h " : "") + mClamped + "m " + suffix
            }
        }
    }
}
