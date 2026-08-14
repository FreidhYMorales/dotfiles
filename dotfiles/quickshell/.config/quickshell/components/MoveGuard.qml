import QtQuick

// Detects real cursor movement over a surface, filtering out Wayland's
// synthetic "pointer enter" — a new/remapped surface reports the cursor's
// current (possibly stationary) position as soon as it maps, which a plain
// onPositionChanged handler sees identically to an actual move. The first
// report after (re)arming is treated as a baseline instead of movement;
// only a later report past `moveThreshold` counts as real.
//
// Call `check(mouseX, mouseY)` from a MouseArea's onPositionChanged and
// `reset()` whenever the surface (re)appears — see LauncherContent.qml,
// ScreensaverForm.qml and LockIdle.qml for the three shapes this drives
// (hover-follow gate, gate, and instant lock-dismiss respectively).
QtObject {
    id: root

    property bool armed: false
    property real baseX: 0
    property real baseY: 0
    property real moveThreshold: 4

    signal realMove()

    function reset() {
        root.armed = false
    }

    function check(x, y) {
        if (!root.armed) {
            root.armed = true
            root.baseX = x
            root.baseY = y
            return
        }
        if (Math.abs(x - root.baseX) > root.moveThreshold || Math.abs(y - root.baseY) > root.moveThreshold)
            root.realMove()
    }
}
