pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int current: 0
    property int max:     100
    property int percent: max > 0 ? Math.round(current / max * 100) : 0

    Component.onCompleted: pollProc.running = true

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

    // Watch udev backlight events instead of polling — the kernel emits a
    // CHANGE uevent on every brightness write (hotkeys, brightnessctl, any
    // other writer), same pattern as Battery.qml/Network.qml. inotify
    // doesn't fire on sysfs virtual files, but udev does; this replaces a
    // brightnessctl fork every 500ms forever with one long-lived
    // `udevadm monitor` process plus a fork only when brightness actually
    // changes.
    Process {
        running: true
        command: ["udevadm", "monitor", "--subsystem-match=backlight", "--udev"]
        stdout: SplitParser {
            onRead: _ => pollProc.running = true
        }
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
