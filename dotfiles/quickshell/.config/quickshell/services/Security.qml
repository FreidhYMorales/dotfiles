pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils"

// Lockscreen unlock-method settings, managed from the launcher's ">security"
// panel (modules/launcher/SecurityForm.qml). Only fingerprintEnabled is
// persisted (~/.local/state/quickshell/security.json, same FileView +
// _restored idiom as IdleManager.qml) — enrollment status itself is never
// cached, always queried live from fprintd via refresh() so this can never
// drift from the real PAM-visible state.
Singleton {
    id: root

    property bool fingerprintEnabled: true

    // --- live fprintd state (never persisted) ---
    property var enrolledFingerNames: []
    readonly property bool hasEnrolledFingerprint: root.enrolledFingerNames.length > 0

    property bool enrolling: false
    property string enrollMessage: ""
    property int enrollStageCount: 0

    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""

    function refresh() {
        listProc.running = false
        listProc.running = true
    }

    function startEnroll() {
        if (root.enrolling) return
        root.enrolling = true
        root.enrollStageCount = 0
        root.enrollMessage = "Touch the fingerprint sensor"
        enrollProc.running = true
    }

    // fprintd-enroll has no clean "cancel" of its own — killing the process
    // (running=false, same SIGTERM/SIGKILL behavior Recorder.qml documents)
    // is safe here, unlike the video-file case that comment warns about:
    // worst case is just an incomplete enrollment, nothing left corrupted on
    // disk.
    function cancelEnroll() {
        if (!root.enrolling) return
        enrollProc.running = false
        root.enrolling = false
        root.enrollMessage = ""
        root.refresh()
    }

    function deleteFingerprint() {
        deleteProc.running = true
    }

    // --- fprintd-list <user> — lines look like " - #0: right-index-finger" ---
    Process {
        id: listProc
        command: ["fprintd-list", root.userName]
        stdout: StdioCollector {
            id: listStdout
            onStreamFinished: {
                const names = []
                const re = /-\s*#\d+:\s*(\S+)/g
                let m
                while ((m = re.exec(listStdout.text)) !== null) names.push(m[1])
                root.enrolledFingerNames = names
            }
        }
    }

    // --- fprintd-enroll — streams "Enroll result: <status>" per touch. Full
    // status enum per fprint.freedesktop.org Device.EnrollStatus:
    //   enroll-stage-passed          non-terminal, one successful touch
    //   enroll-retry-scan / enroll-swipe-too-short / enroll-too-fast /
    //   enroll-finger-not-centered / enroll-remove-and-retry
    //                                 non-terminal, bad touch, keep trying
    //   enroll-completed             terminal, success
    //   enroll-failed / enroll-disconnected / enroll-unknown-error /
    //   enroll-data-full / enroll-duplicate
    //                                 terminal, failure
    // ---
    Process {
        id: enrollProc
        running: false
        command: ["fprintd-enroll", "-f", "right-index-finger", root.userName]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/Enroll result:\s*(\S+)/)
                if (!m) return
                const status = m[1]
                if (status === "enroll-stage-passed") {
                    root.enrollStageCount++
                    root.enrollMessage = "Touch the sensor again"
                } else if (status === "enroll-completed") {
                    root.enrolling = false
                    root.enrollMessage = ""
                    root.refresh()
                } else if (status === "enroll-failed" || status === "enroll-disconnected" ||
                           status === "enroll-unknown-error" || status === "enroll-data-full" ||
                           status === "enroll-duplicate") {
                    root.enrolling = false
                    root.enrollMessage = ""
                } else {
                    root.enrollMessage = ({
                        "enroll-retry-scan":          "Try scanning again",
                        "enroll-swipe-too-short":     "Swipe was too short — try again",
                        "enroll-too-fast":            "Too fast — try again slower",
                        "enroll-finger-not-centered": "Center your finger on the sensor",
                        "enroll-remove-and-retry":    "Remove your finger and try again"
                    })[status] || "Try again"
                }
            }
        }
        // Covers the process dying (cancelEnroll, or a crash/kill) without
        // ever emitting a terminal "Enroll result" line — the guard means
        // this is a no-op on the normal completed/failed paths above, which
        // already clear `enrolling` themselves before exit fires.
        onExited: (exitCode, exitStatus) => {
            if (root.enrolling) {
                root.enrolling = false
                root.enrollMessage = ""
            }
        }
    }

    Process {
        id: deleteProc
        running: false
        command: ["fprintd-delete", root.userName]
        onExited: root.refresh()
    }

    // --- persistence (~/.local/state/quickshell/security.json) ---
    property bool _restored: false

    onFingerprintEnabledChanged: if (_restored) _persist()

    Process {
        id: mkStateDirProc
        command: ["mkdir", "-p", Paths.appState]
    }

    FileView {
        id: stateFile
        path: Paths.securityStatePath
        watchChanges: false
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                if (saved.fingerprintEnabled !== undefined) root.fingerprintEnabled = saved.fingerprintEnabled
            } catch (e) {
                console.warn("Security: failed to parse security state:", e)
            }
            root._restored = true
        }
        onLoadFailed: root._restored = true
    }

    function _persist() {
        mkStateDirProc.running = true
        stateFile.setText(JSON.stringify({ fingerprintEnabled: root.fingerprintEnabled }))
    }

    Component.onCompleted: {
        mkStateDirProc.running = true
        root.refresh()
    }
}
