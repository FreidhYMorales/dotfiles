pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int  volume: 100
    property bool muted:  false

    Component.onCompleted: volProc.running = true

    // Subscribe to PulseAudio/PipeWire events — fires volume query instantly on sink change
    Process {
        id: subscriber
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("on sink #") && !volProc.running)
                    volProc.running = true
            }
        }
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/Volume:\s*([\d.]+)/)
                if (m) root.volume = Math.round(parseFloat(m[1]) * 100)
                root.muted = line.includes("[MUTED]")
            }
        }
    }

    function setVolume(v) {
        setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@",
                              Math.max(0, Math.min(150, v)) + "%"]
        setVolProc.running = true
    }

    function toggleMute() {
        muteProc.running = true
    }

    Process { id: setVolProc; running: false }
    Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        running: false
    }
}
