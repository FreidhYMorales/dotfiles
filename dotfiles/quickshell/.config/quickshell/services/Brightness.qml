pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int current: 0
    property int max:     100
    property int percent: max > 0 ? Math.round(current / max * 100) : 0

    // Read max brightness once at startup
    Process {
        running: true
        command: ["brightnessctl", "max"]
        stdout: SplitParser {
            onRead: line => {
                const v = parseInt(line.trim())
                if (!isNaN(v) && v > 0) root.max = v
            }
        }
    }

    // Poll current brightness — inotify does not fire on sysfs virtual files,
    // so FileView watchChanges would never detect external changes (keyboard keys)
    Timer {
        interval: 250
        running:  true
        repeat:   true
        onTriggered: pollProc.running = true
    }

    Process {
        id: pollProc
        command: ["brightnessctl", "get"]
        stdout: SplitParser {
            onRead: line => {
                const v = parseInt(line.trim())
                if (!isNaN(v) && v !== root.current) root.current = v
            }
        }
    }

    function set(pct) {
        const clamped = Math.max(1, Math.min(100, pct))
        setProc.command = ["brightnessctl", "set", clamped + "%"]
        setProc.running = true
        root.current = Math.round(clamped / 100 * root.max)
    }

    Process { id: setProc; running: false }
}
