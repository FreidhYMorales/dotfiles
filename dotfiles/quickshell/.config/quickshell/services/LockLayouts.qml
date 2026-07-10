pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Keyboard layout list + switcher for the lockscreen, replacing SDDM's
// `keyboard.layouts`/`keyboard.currentLayout` (no Quickshell equivalent)
// with Hyprland IPC. Same Process+python3-json shell-out pattern as
// services/Hypr.qml's kbProc.
Singleton {
    id: root

    property var layouts: [] // array of short codes, e.g. ["us", "es"]
    property int currentLayout: 0
    property string device: ""

    function switchTo(index) {
        if (!root.device || index < 0 || index >= root.layouts.length) return
        Quickshell.execDetached(["hyprctl", "switchxkblayout", root.device, String(index)])
        root.currentLayout = index
    }

    Process {
        id: queryProc
        command: ["bash", "-c", "python3 -c \"import json,subprocess; opt=json.loads(subprocess.run(['hyprctl','getoption','input:kb_layout','-j'],capture_output=True,text=True).stdout); devs=json.loads(subprocess.run(['hyprctl','devices','-j'],capture_output=True,text=True).stdout); kbs=[k for k in devs.get('keyboards',[]) if k.get('main',False)]; kb=kbs[0] if kbs else {}; print(json.dumps({'layouts':[l.strip() for l in opt.get('str','').split(',') if l.strip()],'index':kb.get('active_layout_index',0),'device':kb.get('name','')}))\" 2>/dev/null"]
        stdout: SplitParser {
            onRead: line => {
                const text = line.trim()
                if (!text) return
                try {
                    const data = JSON.parse(text)
                    root.layouts = data.layouts || []
                    root.currentLayout = data.index || 0
                    root.device = data.device || ""
                } catch (e) {
                    console.warn("LockLayouts: failed to parse hyprctl output:", e)
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            queryProc.running = false
            queryProc.running = true
        }
    }
}
