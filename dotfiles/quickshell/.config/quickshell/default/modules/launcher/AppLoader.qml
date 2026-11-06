import Quickshell
import Quickshell.Io
import QtQuick
import "../../utils"

// Runs list-apps.py and parses its JSON output into `apps` — kept separate
// from LauncherContent so the launcher's app list is a single reload() call
// instead of inline Process/SplitParser wiring.
QtObject {
    id: loader

    property var apps: []
    property string _buf: ""

    function reload() {
        loader._buf = ""
        proc.running = true
    }

    property Process proc: Process {
        command: ["python3", Paths.scripts + "/list-apps.py"]
        stdout: SplitParser {
            onRead: line => { loader._buf += line }
        }
        onRunningChanged: {
            if (running) return
            try {
                loader.apps = JSON.parse(loader._buf)
            } catch (e) {
                console.warn("Launcher: failed to parse app list:", e)
            }
            loader._buf = ""
        }
    }
}
