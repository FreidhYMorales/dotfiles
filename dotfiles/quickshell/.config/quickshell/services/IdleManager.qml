pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../utils"

// Idle chain: screensaver+lock fire TOGETHER, suspend separately.
//
// The session actually locks (WlSessionLock.locked = true) as soon as the
// screensaver threshold hits, not at a later separate "lock" threshold.
// This isn't a security relaxation — modules/lock/LockSurface.qml keeps the
// password prompt hidden and dismisses freely on input (no password) until
// lockGraceElapsed also flips true. It's forced by ext-session-lock-v1: once
// locked, the compositor's exclusive lock surface replaces ANY other surface
// unconditionally, including a separate screensaver overlay — so having two
// distinct surfaces (screensaver, then lock) meant the video/image restarted
// from scratch at the handoff, visible as a flicker. Locking immediately and
// rendering the screensaver content INSIDE LockSurface itself the whole time
// means there's only ever one media pipeline, so nothing ever restarts.
//
// Timeouts and screensaver source are persisted
// (~/.local/state/quickshell/idle.json); caffeineMode is session-only (never
// persisted, always starts off). respectInhibitors on every monitor means
// modules/background/Background.qml's IdleInhibitor (enabled when
// caffeineMode is on) pauses all three stages with no extra wiring here.
Singleton {
    id: root

    property real screensaverTimeoutMin: 3
    property real lockTimeoutMin: 5
    property real suspendTimeoutMin: 15
    property bool screensaverUseWallpaper: true
    property string screensaverPath: ""

    // Session-only — always starts off, never written to disk.
    property bool caffeineMode: false

    readonly property string effectiveScreensaverSource: screensaverUseWallpaper ? Wallpapers.current : screensaverPath

    // True once lockTimeoutMin (additional idle time, same reference point
    // as screensaverMonitor) has elapsed AT LEAST ONCE during the current
    // lock cycle — LockSurface checks this to decide whether input should
    // dismiss the lock for free or require a password.
    //
    // This is deliberately a LATCH, not a direct read of lockMonitor.isIdle.
    // The input that triggers the check is real activity, so it resets
    // lockMonitor.isIdle to false in the exact same tick — reading isIdle
    // directly always sees false at the moment it matters, no matter how
    // long the grace period already ran (confirmed empirically: the log
    // showed lockMonitor flip to false a fraction of a millisecond before
    // LockSurface's own check ran, every time). The latch survives that
    // reset; only a new lock cycle (screensaverMonitor firing again) clears it.
    property bool lockGraceElapsed: false

    // IdleMonitor.timeout is in SECONDS (not ms) — confirmed from Quickshell's
    // own source (monitor.hpp): "The amount of time in seconds the idle
    // monitor should wait before reporting an idle state."
    //
    // `enabled` is gated on `_restored` (state loaded from disk) on purpose:
    // these properties start at their hardcoded defaults (3/5/15 min) and
    // only take their real persisted values once the FileView below
    // finishes loading. Without this gate, a fresh process start could
    // briefly create the underlying idle-notify object with `enabled: true`
    // against the DEFAULT timeout, then have `timeout` change under it a
    // moment later — a race that intermittently left isIdle never firing at
    // all for the rest of the process's life (observed empirically: some
    // fresh instances never fired even after minutes, others worked first try,
    // no other code path differed). Not enabling until state is settled
    // avoids ever creating the notification object against a stale value.
    IdleMonitor {
        id: screensaverMonitor
        enabled: root._restored && root.screensaverTimeoutMin > 0
        timeout: root.screensaverTimeoutMin * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) {
                root.lockGraceElapsed = false
                Quickshell.execDetached(["qs", "ipc", "-p", Quickshell.shellDir, "call", "lock", "lockFromIdle"])
            }
        }
    }

    // Must fire strictly AFTER screensaverMonitor — both watch the same real
    // idle clock (time since last input), not sequential/relative stages, so
    // a configured lockTimeoutMin <= screensaverTimeoutMin makes both
    // isIdleChanged handlers fire at essentially the same tick. Their order
    // is not guaranteed: screensaverMonitor's handler resets
    // lockGraceElapsed to false while this one sets it to true, and if the
    // reset runs last, lockGraceElapsed gets stuck at false for the rest of
    // the idle period — no fresh false->true transition happens again
    // without real activity in between, so the password prompt would never
    // engage and the screensaver would sit there indefinitely. Padding the
    // effective timeout by a few real seconds guarantees this monitor always
    // idles out after screensaverMonitor already has, regardless of what
    // raw lockTimeoutMin the user configures via the >screensaver sliders.
    readonly property real _lockMonitorTimeoutSec:
        Math.max(root.lockTimeoutMin * 60, root.screensaverTimeoutMin * 60 + 5)

    IdleMonitor {
        id: lockMonitor
        enabled: root._restored && root.lockTimeoutMin > 0
        timeout: root._lockMonitorTimeoutSec
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lockGraceElapsed = true
    }

    IdleMonitor {
        id: suspendMonitor
        enabled: root._restored && root.suspendTimeoutMin > 0
        timeout: root.suspendTimeoutMin * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) Quickshell.execDetached(["systemctl", "suspend"])
        }
    }

    // --- persistence (~/.local/state/quickshell/idle.json) ---
    property bool _restored: false

    onScreensaverTimeoutMinChanged: if (_restored) _persist()
    onLockTimeoutMinChanged: if (_restored) _persist()
    onSuspendTimeoutMinChanged: if (_restored) _persist()
    onScreensaverUseWallpaperChanged: if (_restored) _persist()
    onScreensaverPathChanged: if (_restored) _persist()

    Process {
        id: mkStateDirProc
        command: ["mkdir", "-p", Paths.appState]
    }

    FileView {
        id: stateFile
        path: Paths.idleStatePath
        watchChanges: false
        onLoaded: {
            try {
                const saved = JSON.parse(text())
                if (saved.screensaverTimeoutMin !== undefined) root.screensaverTimeoutMin = saved.screensaverTimeoutMin
                if (saved.lockTimeoutMin !== undefined)        root.lockTimeoutMin        = saved.lockTimeoutMin
                if (saved.suspendTimeoutMin !== undefined)     root.suspendTimeoutMin     = saved.suspendTimeoutMin
                if (saved.screensaverUseWallpaper !== undefined) root.screensaverUseWallpaper = saved.screensaverUseWallpaper
                if (saved.screensaverPath !== undefined)       root.screensaverPath       = saved.screensaverPath
            } catch (e) {
                console.warn("IdleManager: failed to parse idle state:", e)
            }
            root._restored = true
        }
        onLoadFailed: root._restored = true
    }

    function _persist() {
        mkStateDirProc.running = true
        stateFile.setText(JSON.stringify({
            screensaverTimeoutMin: root.screensaverTimeoutMin,
            lockTimeoutMin: root.lockTimeoutMin,
            suspendTimeoutMin: root.suspendTimeoutMin,
            screensaverUseWallpaper: root.screensaverUseWallpaper,
            screensaverPath: root.screensaverPath
        }))
    }

    Component.onCompleted: mkStateDirProc.running = true
}
