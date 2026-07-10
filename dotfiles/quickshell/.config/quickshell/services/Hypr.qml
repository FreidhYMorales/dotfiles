pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Hyprland state service — keyboard modifiers, layout, active window.
// Exposes Caelestia-compatible API used in StateMessage.qml.
Singleton {
    id: root

    // Keyboard state
    property bool   capsLock:       false
    property bool   numLock:        false
    property string defaultKbLayout: ""
    property string kbLayoutFull:   "English (US)"
    property string kbLayout:       "us"

    // Active window info
    property string activeClass: ""
    property string activeTitle: ""

    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel
    readonly property var toplevels:   Hyprland.toplevels
    readonly property var workspaces:  Hyprland.workspaces
    readonly property var monitors:    Hyprland.monitors
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property HyprlandMonitor   focusedMonitor:   Hyprland.focusedMonitor

    Process {
        id: capsProc
        command: ["bash", "-c", "cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: line => { root.capsLock = line.trim() === "1" }
        }
    }

    Process {
        id: numProc
        command: ["bash", "-c", "cat /sys/class/leds/input*::numlock/brightness 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: line => { root.numLock = line.trim() === "1" }
        }
    }

    Process {
        id: kbProc
        command: ["bash", "-c", "hyprctl devices -j 2>/dev/null | python3 -c \"import sys,json; devs=json.load(sys.stdin); kbs=[k for k in devs.get('keyboards',[]) if k.get('main',False)]; print(kbs[0].get('active_keymap','') if kbs else '')\" 2>/dev/null"]
        stdout: SplitParser {
            onRead: line => {
                const km = line.trim()
                if (km) {
                    root.kbLayoutFull = km
                    root.kbLayout     = km.split(" ")[0].toLowerCase().substring(0, 2) || "us"
                    if (!root.defaultKbLayout) root.defaultKbLayout = root.kbLayout
                }
            }
        }
    }

    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            capsProc.running = false; capsProc.running = true
            numProc.running  = false; numProc.running  = true
            kbProc.running   = false; kbProc.running   = true
        }
    }

    function dispatch(request) {
        Hyprland.dispatch(request)
    }
}
