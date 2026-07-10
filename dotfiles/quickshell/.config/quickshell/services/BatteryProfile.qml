pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // "power-saver" | "balanced" | "performance"
    property string current: "balanced"

    Component.onCompleted: getProc.running = true

    Process {
        id: getProc
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: line => { const v = line.trim(); if (v) root.current = v }
        }
    }

    function set(profile) {
        setProc.command = ["powerprofilesctl", "set", profile]
        setProc.running = true
        root.current = profile
    }

    Process { id: setProc; running: false }
}
