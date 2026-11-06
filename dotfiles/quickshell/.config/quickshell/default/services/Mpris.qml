pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    property int activeIdx: -1
    property var player:    null

    // Explicit properties — property var doesn't track sub-property changes via bindings
    property bool   playing:  false
    property real   position: 0
    property string title:    ""
    property string artist:   ""
    property string artUrl:   ""

    readonly property var    allPlayers:  Mpris.players.values ?? []
    readonly property int    playerCount: allPlayers?.length ?? 0
    readonly property string playerName:  playerDisplayName(player)

    // Players excluding the active one — used for the selector list
    readonly property var otherPlayers: {
        const all = allPlayers ?? []
        const out = []
        for (let i = 0; i < all.length; i++) {
            if (i !== activeIdx) out.push({ idx: i, mp: all[i] })
        }
        return out
    }
    readonly property int otherCount: otherPlayers.length
    readonly property bool   hasPlayer:   player !== null
    readonly property real   length:      player?.length   ?? 0
    readonly property bool   canNext:     player?.canGoNext     ?? false
    readonly property bool   canPrev:     player?.canGoPrevious ?? false

    // Immediate updates when the active player signals a change
    Connections {
        target: root.player
        function onPositionChanged()   { root.position = root.player?.position ?? 0 }
        function onTrackTitleChanged() { root.title    = root.player?.trackTitle  ?? "" }
        function onTrackArtistChanged(){ root.artist   = root.player?.trackArtist ?? "" }
        function onTrackArtUrlChanged(){ root.artUrl   = root.player?.trackArtUrl ?? "" }
    }

    function playerDisplayName(p) {
        if (!p) return ""
        if (typeof p.identity === "string" && p.identity.length > 0) return p.identity
        const id = typeof p.instanceId === "string" ? p.instanceId : ""
        return id.split(".")[0] || "player"
    }

    function selectPlayer(idx) {
        root.activeIdx = idx
        root._refresh()
    }

    function _syncPlayer() {
        root.playing  = root.player?.playbackStatus === 1
        root.position = root.player?.position ?? 0
        root.title    = root.player?.trackTitle  ?? ""
        root.artist   = root.player?.trackArtist ?? ""
        root.artUrl   = root.player?.trackArtUrl ?? ""
    }

    function _refresh() {
        const values = Mpris.players.values
        const n      = values?.length ?? 0
        if (n === 0) { root.player = null; root.activeIdx = -1; root._syncPlayer(); return }
        if (root.activeIdx >= 0 && root.activeIdx < n) {
            root.player = values[root.activeIdx]
        } else {
            let picked = 0
            for (let i = 0; i < n; i++) {
                if (values[i].playbackStatus === 1) { picked = i; break }
            }
            root.activeIdx = picked
            root.player    = values[picked]
        }
        root._syncPlayer()
    }

    Component.onCompleted: _refresh()

    Connections {
        target: Mpris.players
        function onValuesChanged() { root._refresh() }
    }

    // Poll while a player is active — covers position + playback status (no change signal)
    Timer {
        interval: 1000
        running:  root.player !== null
        repeat:   true
        onTriggered: root._refresh()
    }

    function togglePlay() { player?.togglePlaying() }
    function next()       { player?.next() }
    function previous()   { player?.previous() }
}
