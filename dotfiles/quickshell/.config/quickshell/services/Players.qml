pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Mpris

// MPRIS media player service with Caelestia-compatible API.
// Exposes: active (MprisPlayer), list, getArtUrl()
QtObject {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values
    readonly property MprisPlayer active:     Mpris.players.values[0] ?? null

    function getArtUrl(player) {
        if (!player) return ""
        if (player.trackArtUrl) return player.trackArtUrl
        const url = player.metadata?.["xesam:url"] ?? ""
        if (url.startsWith("https://www.youtube.com/watch")) {
            const id = url.match(/[?&]v=([\w-]{11})/)?.[1]
            return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : ""
        }
        return ""
    }
}
