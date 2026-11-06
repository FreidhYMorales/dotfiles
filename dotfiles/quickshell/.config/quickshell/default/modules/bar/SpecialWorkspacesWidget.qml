pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../services"
import "../../components"

Row {
    id: specialRow
    spacing: 5

    // Per-monitor palette (bar/panels only — see Colours.paletteFor). Defaults
    // to the shared global palette so this widget still works wherever else
    // it might be instantiated without a screen context.
    property var colors: Colours.palette

    // iconActive: shown while the special workspace is the one currently
    // displayed on its monitor. iconOccupied: shown while it has windows but
    // is hidden — mirrors the ●/○ treatment WorkspacesWidget uses for
    // numbered workspaces. Music/messaging reuse one glyph for both states
    // (color/size carries the distinction) since there's no outline variant.
    //
    // NOTE: codepoints typed from memory, no local Nerd Fonts cheat-sheet to
    // check against — verify live once the bar reloads and swap here if any
    // of these render as tofu/wrong glyph. Escapes used instead of literal
    // glyph characters because astral-plane PUA chars got mangled in transit
    // when pasted literally.
    // yOffset: per-icon manual optical-centering nudge (logical px, +down).
    // Qt's Text anchors.centerIn uses the font's ascent/descent metrics, not
    // each glyph's actual ink bounds — a speech-bubble glyph with a "tail"
    // hanging below its main body reads visually high with plain centering.
    // Confirmed live (screenshot, cropped/zoomed) that "messaging" sits
    // ~2-3px above the workspace circles' shared center; magic/music were
    // never visually verified (typed from memory, no live check yet per the
    // NOTE above) so they keep the prior default (0) until actually seen.
    readonly property var specials: [
        { name: "magic",     iconActive: "",    iconOccupied: "",  yOffset: 0 }, // nf-cod-star_full / nf-cod-star_empty
        { name: "music",     iconActive: "󰎈", iconOccupied: "󰽴", yOffset: 0 }, // nf-md-music_note_2 / nf-md-music_note_outline
        { name: "messaging", iconActive: "󰍨", iconOccupied: "󱜽", yOffset: 2 }, // nf-md-message_reply_text / nf-md-message_reply_outline
    ]

    // Collapses the whole cluster to zero width (and zero Row spacing in the
    // parent pill) when nothing is occupied AND nothing is currently shown —
    // Row positioners skip invisible children entirely, unlike a plain
    // width:0 item. A special counts as "shown" even with zero windows,
    // mirroring how WorkspacesWidget reveals numbered workspaces 6-10 just by
    // being focused, occupied or not.
    visible: shownCount > 0
    property int shownCount: {
        let n = 0
        for (let i = 0; i < specialRow.specials.length; i++) {
            const name = specialRow.specials[i].name
            const item = specialRow.findSpecial(name)
            const occupied = !!item && item.wsWindows > 0
            const active   = specialRow.shownSpecial === name
            if (occupied || active) n++
        }
        return n
    }

    // Probe: same trick as WorkspacesWidget — Repeater over Hyprland.workspaces
    // gives reactive access to name/toplevels without broken [i] access on
    // the ObjectModel. This is also the only place special workspaces show up
    // at all — Quickshell's HyprlandMonitor has no separate "specialWorkspace"
    // property like `hyprctl monitors -j` does.
    //
    // wsWindows reads toplevels.values.length, not toplevels.count — Quickshell's
    // ObjectModel has no "count" property (only "values", a plain list), so
    // ".count" silently evaluates to undefined -> coerces to 0 on an int
    // property. Confirmed by reading Quickshell's own source
    // (src/core/model.hpp) — this was the actual bug, not a naming mismatch.
    Repeater {
        id: hyprSpecials
        model: Hyprland.workspaces
        delegate: Item {
            required property var modelData
            property string wsName:    modelData.name
            property int    wsWindows: modelData.toplevels.values.length
            visible: false; width: 0; height: 0
        }
    }

    function findSpecial(shortName) {
        const fullName = "special:" + shortName
        for (let i = 0; i < hyprSpecials.count; i++) {
            const item = hyprSpecials.itemAt(i)
            if (item && item.wsName === fullName) return item
        }
        return null
    }

    // HyprlandWorkspace.active is never true for special workspaces — this
    // Quickshell build's Hyprland IPC connector has no handling at all for
    // the "activespecial" event (confirmed in connection.cpp: only
    // "workspacev2" flips a workspace's active flag). So "which special is
    // currently shown" is tracked here by hand from the raw event stream
    // instead of reading a property.
    property string shownSpecial: ""
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activespecial") return
            const parts = event.parse(2)
            const wsName = parts[0]
            specialRow.shownSpecial = wsName.startsWith("special:") ? wsName.slice(8) : ""
        }
    }

    Repeater {
        model: specialRow.specials
        delegate: Item {
            required property var modelData

            property var wsItem: {
                const _ = hyprSpecials.count
                return specialRow.findSpecial(modelData.name)
            }
            property bool isOccupied: !!wsItem && wsItem.wsWindows > 0
            property bool isActive:   specialRow.shownSpecial === modelData.name
            property bool isShown:    isActive || isOccupied

            clip: true
            implicitWidth:  isShown ? (isActive ? 28 : 22) : 0
            implicitHeight: 26

            Behavior on implicitWidth { NumberAnimation { duration: 120; easing.type: Easing.InOutCubic } }

            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1 + parent.modelData.yOffset
                text:           parent.isActive ? parent.modelData.iconActive : parent.modelData.iconOccupied
                color:          parent.isActive ? specialRow.colors.m3primary : specialRow.colors.m3onSurfaceVariant
                font.family:    Style.fontFamily
                font.pixelSize: parent.isActive ? 20 : 15
                Behavior on color          { CAnim {} }
                Behavior on font.pixelSize { NumberAnimation { duration: 120; easing.type: Easing.InOutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                // Same Lua-bridge dispatch quirk as WorkspacesWidget —
                // Hyprland.dispatch() is dead in this fork, route through
                // hyprctl instead.
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch",
                    "hl.dsp.workspace.toggle_special(\"" + parent.modelData.name + "\")"])
            }
        }
    }
}
