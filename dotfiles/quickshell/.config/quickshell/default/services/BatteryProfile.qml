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

    // Watch power-profiles-daemon PropertiesChanged (ActiveProfile) — fires
    // immediately when the profile changes from outside Quickshell (udev
    // AC/battery auto-switch, powerprofilesctl in a terminal, etc).
    Process {
        running: true
        command: [
            "dbus-monitor", "--system",
            "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='net.hadess.PowerProfiles'"
        ]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("signal"))
                    getProc.running = true
            }
        }
    }

    function set(profile) {
        setProc.command = ["powerprofilesctl", "set", profile]
        setProc.running = true
        root.current = profile
    }

    Process { id: setProc; running: false }
}
