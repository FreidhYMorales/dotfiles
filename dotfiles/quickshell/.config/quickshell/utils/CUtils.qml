pragma Singleton
import QtQuick

// Common utility functions — Caelestia-compatible API.
QtObject {
    id: root

    function clamp(value, min, max) {
        return Math.max(min, Math.min(max, value))
    }

    function lerp(a, b, t) {
        return a + (b - a) * t
    }

    function formatDuration(seconds) {
        const m = Math.floor(seconds / 60)
        const s = Math.floor(seconds % 60)
        return `${m}:${s < 10 ? "0" : ""}${s}`
    }

    // toLocalFile: strips file:// prefix from a URL string
    function toLocalFile(url) {
        return url.toString().replace(/^file:\/\//, "")
    }
}
