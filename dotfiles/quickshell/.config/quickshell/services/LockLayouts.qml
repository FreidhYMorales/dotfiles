pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Keyboard layout list + switcher for the lockscreen, replacing SDDM's
// `keyboard.layouts`/`keyboard.currentLayout` (no Quickshell equivalent)
// with Hyprland IPC via two native `hyprctl -j` Process calls (same pattern
// as services/Keybinds.qml — no shell/python3 subshell in between).
//
// Polling only runs while Visibilities.locked is true (mirrored from
// modules/lock/Lock.qml's WlSessionLock) — this data is meaningless outside
// the lockscreen, so there's no reason to poll while unlocked.
Singleton {
    id: root

    property var layouts: [] // array of short codes, e.g. ["us", "es"]
    property int currentLayout: 0
    property string device: ""

    property string _optionStr: ""
    property int _kbIndex: 0
    property string _kbName: ""

    function switchTo(index) {
        if (!root.device || index < 0 || index >= root.layouts.length) return
        Quickshell.execDetached(["hyprctl", "switchxkblayout", root.device, String(index)])
        root.currentLayout = index
    }

    function refresh() {
        optionProc.running = true
        devicesProc.running = true
    }

    function _apply() {
        root.layouts = root._optionStr.split(",").map(l => l.trim()).filter(l => l.length > 0)
        root.currentLayout = root._kbIndex
        root.device = root._kbName
    }

    Process {
        id: optionProc
        command: ["hyprctl", "getoption", "input:kb_layout", "-j"]
        stdout: StdioCollector {
            id: optionStdout
            onStreamFinished: {
                try {
                    root._optionStr = JSON.parse(optionStdout.text).str || ""
                    root._apply()
                } catch (e) {
                    console.warn("LockLayouts: failed to parse kb_layout option:", e)
                }
            }
        }
    }

    Process {
        id: devicesProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            id: devicesStdout
            onStreamFinished: {
                try {
                    const devs = JSON.parse(devicesStdout.text)
                    const kbs  = (devs.keyboards || []).filter(k => k.main)
                    const kb   = kbs[0] || {}
                    root._kbIndex = kb.active_layout_index || 0
                    root._kbName  = kb.name || ""
                    root._apply()
                } catch (e) {
                    console.warn("LockLayouts: failed to parse hyprctl devices output:", e)
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: Visibilities.locked
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
