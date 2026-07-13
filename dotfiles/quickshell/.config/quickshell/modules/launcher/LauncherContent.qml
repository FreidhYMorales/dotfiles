pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "../../utils"
import "../../services"
import "../../components"

Item {
    id: root

    property string stage:         "closed"
    property var    apps:          []
    property string _buf:          ""
    property int    selectedIndex: 0
    // Which monitor the ">wallpaper" picker is currently targeting — ""
    // means "all monitors" (Wallpapers.commit's default/sync behavior).
    property string activeScreen:  ""

    readonly property int itemH:   64
    readonly property int searchH: 56
    // Fixed height for the wallpaper carousel — unlike the row-based lists,
    // it doesn't grow with the result count (it's an infinite horizontal
    // PathView, not a capped-at-5-rows vertical list).
    readonly property int carouselH: 190
    // Extra height reserved for the monitor-tabs row, only shown when 2+
    // screens are connected.
    readonly property int monitorTabsH: 28

    // ">" alone (or ">partial-name") lists available commands; ">wallpaper "/
    // ">theme " (note the trailing space — matches how caelestia's own
    // command prefixes work) switches into that command's own content.
    readonly property var commands: [
        { id: "wallpaper",   name: "Wallpaper",   description: "Choose the desktop wallpaper", icon: "󰸉" },
        { id: "theme",       name: "Theme",       description: "Choose the color theming mode", icon: "󰏘" },
        { id: "screensaver", name: "Screensaver", description: "Configure screensaver, lock and suspend", icon: "󰍹" },
        { id: "keybinds",    name: "Keybinds",    description: "Keyboard shortcuts cheatsheet", icon: "󰌌" },
        { id: "webapp",      name: "Web App",     description: "Install a web app launcher",      icon: "󰖟" }
    ]

    readonly property string mode: {
        const t = searchField.text
        if (t.startsWith(">wallpaper "))   return "wallpapers"
        if (t.startsWith(">theme "))       return "themes"
        if (t.startsWith(">screensaver ")) return "screensaver"
        if (t.startsWith(">keybinds "))    return "keybinds"
        if (t.startsWith(">webapp "))      return "webapp"
        if (t.startsWith(">"))             return "commands"
        return "apps"
    }
    readonly property string query: {
        const t = searchField.text
        if (root.mode === "wallpapers")   return t.slice(">wallpaper ".length).trim().toLowerCase()
        if (root.mode === "themes")       return t.slice(">theme ".length).trim().toLowerCase()
        if (root.mode === "screensaver")  return ""
        if (root.mode === "keybinds")     return ""
        if (root.mode === "webapp")       return ""
        if (root.mode === "commands")     return t.slice(1).trim().toLowerCase()
        return t.toLowerCase()
    }

    // Strips desktop-entry field codes (%f, %U, etc.) an exec= string may
    // still carry, then collapses/trims whitespace left behind.
    function sanitizeExec(exec) {
        return exec.replace(/%[fFuUdDnNickvm%]/g, "").replace(/\s+/g, " ").trim()
    }

    // Picking a command from the ">" list fills in its prefix + a trailing
    // space and keeps typing from there — it doesn't commit/close anything.
    function pickCommand(cmdId) {
        searchField.text = ">" + cmdId + " "
        searchField.cursorPosition = searchField.text.length
    }
    // Light/dark toggle — resets to the currently committed value whenever
    // the picker is (re)entered. Also mirrors whatever mode row is picked
    // next (see the ListView delegates' onClicked below).
    property bool pendingIsLight: Colours.isLight

    // Guards the wallpaper carousel's hover-to-select against Wayland's
    // synthetic "pointer enter" — a new layer surface reports the cursor's
    // CURRENT (possibly hidden, stationary) position as soon as it maps,
    // which HoverHandler sees identically to a real hover. Without this, the
    // carousel could jump to whatever card the mouse happened to already be
    // sitting over the instant the launcher opened, with no real movement
    // involved. Same root cause/fix shape as modules/lock/LockIdle.qml's
    // baseline-and-threshold guard (see idle-screensaver.md gotcha #7/#8).
    property bool _wallpaperRealMove: false

    onModeChanged: {
        Wallpapers.stopPreview()
        root.pendingIsLight = Colours.isLight
        if (root.mode === "themes") Colours.generatePreviews(Wallpapers.actualCurrent, Wallpapers.isVideoPath(Wallpapers.actualCurrent))
        // Re-read hyprctl every time the cheatsheet is opened — cheap, and
        // keeps it correct if keybinds.lua changed and Hyprland reloaded
        // since the shell started.
        if (root.mode === "keybinds") Keybinds.refresh()
        if (root.mode === "webapp") {
            webAppForm.reset()
            Qt.callLater(() => webAppForm.focusName())
        }
        if (root.mode === "wallpapers") {
            root.activeScreen = ""
            root._wallpaperRealMove = false
            // Re-arm the position baseline too — otherwise a stale one from
            // a previous visit to this mode gets compared against next time,
            // which could immediately (and wrongly) look like real movement.
            wallpaperMoveTracker.armed = false
        }
    }

    // Re-evaluates the live preview for whatever card is currently centered
    // in the carousel, scoped to root.activeScreen — shared by carousel
    // navigation and by switching monitor tabs (neither alone changes both
    // selectedIndex and activeScreen at once, so each needs to trigger this).
    function _refreshWallpaperPreview() {
        if (root.mode !== "wallpapers" || root.filtered.length === 0) return
        const idx = Math.min(root.selectedIndex, root.filtered.length - 1)
        if (idx >= 0) Wallpapers.preview(root.filtered[idx].path, root.activeScreen)
    }

    // Toggling light/dark applies immediately to whichever mode is already
    // active, rather than only taking effect once a mode row is also
    // clicked — the toggle alone used to look like it did nothing.
    function toggleLightDark() {
        root.pendingIsLight = !root.pendingIsLight
        Colours.commit(Colours.currentMode, root.pendingIsLight)
    }

    property var filtered: {
        const q = root.query
        if (root.mode === "wallpapers")
            return q ? Wallpapers.entries.filter(e => e.name.toLowerCase().includes(q)) : Wallpapers.entries
        if (root.mode === "themes")
            return q ? Colours.modes.filter(m => m.name.toLowerCase().includes(q)) : Colours.modes
        // Doesn't filter anything — ScreensaverForm/KeybindsList aren't
        // lists driven by this property, so there's nothing here worth
        // computing (would just be pure apps.filter() waste on every
        // keystroke while either mode is active).
        if (root.mode === "screensaver" || root.mode === "keybinds" || root.mode === "webapp")
            return []
        if (root.mode === "commands")
            return q ? root.commands.filter(c => c.name.toLowerCase().includes(q) || c.id.includes(q)) : root.commands
        return q ? root.apps.filter(a => a.name.toLowerCase().includes(q)) : root.apps
    }

    onFilteredChanged: {
        selectedIndex = 0
        // wallpaperCarousel.currentIndex doesn't necessarily reset on its own
        // when the model array is swapped for a new one (e.g. typing a
        // query) — force it back in sync with selectedIndex above.
        if (root.mode === "wallpapers") wallpaperCarousel.currentIndex = 0
    }

    onSelectedIndexChanged: {
        const idx = Math.min(root.selectedIndex, root.filtered.length - 1)
        // wallpaperCarousel (a PathView) snaps itself via highlightRangeMode
        // instead of needing a positionViewAtIndex-style call.
        if (stage === "open") {
            if (root.mode === "apps")        Qt.callLater(() => appList.positionViewAtIndex(root.selectedIndex, ListView.Contain))
            else if (root.mode === "themes") Qt.callLater(() => themeList.positionViewAtIndex(root.selectedIndex, ListView.Contain))
            else if (root.mode === "commands") Qt.callLater(() => commandList.positionViewAtIndex(root.selectedIndex, ListView.Contain))
        }
        root._refreshWallpaperPreview()
    }

    readonly property int listH: {
        if (stage !== "open") return 0
        if (root.mode === "screensaver") return screensaverForm.formH
        if (root.mode === "keybinds")    return keybindsList.formH
        if (root.mode === "webapp")      return webAppForm.formH
        if (root.mode === "wallpapers" && root.filtered.length > 0)
            return root.carouselH + (Quickshell.screens.length > 1 ? root.monitorTabsH + 8 : 0)
        if (filtered.length === 0 && searchField.text.length > 0) return itemH
        return Math.min(filtered.length, 5) * itemH
    }

    readonly property int panelHeight: listH + searchH + (listH > 0 ? 8 : 0)

    // ── State machine ──────────────────────────────────────────────────────

    Connections {
        target: Visibilities
        function onLauncherChanged() {
            if (!Visibilities.launcher) {
                openAnim.stop()
                closeAnim.start()
                Wallpapers.stopPreview()
                return
            }
            closeAnim.stop()
            root._buf = ""
            appsProc.running = true
            openAnim.start()
            // Re-arm the wallpaper hover-movement guard on every fresh open,
            // not just on a mode change — the search text (and so `mode`)
            // can already be "wallpapers" from before the launcher was last
            // closed, in which case onModeChanged wouldn't refire here.
            root._wallpaperRealMove = false
            wallpaperMoveTracker.armed = false
            root.activeScreen = ""
        }
    }

    SequentialAnimation {
        id: openAnim
        ScriptAction { script: root.stage = "precircle" }
        NumberAnimation {
            target: arcCanvas; property: "arcEnd"
            from: 0; to: 360; duration: 320; easing.type: Easing.InOutQuart
        }
        PauseAnimation { duration: 60 }
        ScriptAction  { script: root.stage = "circle" }
        PauseAnimation { duration: 180 }
        ScriptAction  { script: root.stage = "bar" }
        PauseAnimation { duration: 360 }
        ScriptAction  { script: { root.stage = "open"; focusTimer.restart() } }
    }

    SequentialAnimation {
        id: closeAnim
        ScriptAction {
            script: {
                searchField.text = ""
                if (root.stage === "open") root.stage = "bar"
            }
        }
        PauseAnimation { duration: 300 }
        ScriptAction  { script: root.stage = "circle" }
        PauseAnimation { duration: 380 }
        ScriptAction  { script: root.stage = "closing" }
        PauseAnimation { duration: 200 }
        ScriptAction  { script: root.stage = "closed" }
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: searchField.forceActiveFocus()
    }

    // ── Panel rectangle (anchored to bottom, grows upward) ─────────────────

    Rectangle {
        id: panelRect
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        clip: true

        width: {
            switch (stage) {
                case "closed": case "precircle": case "circle": case "closing": return 60
                default: return 600
            }
        }
        height: {
            switch (stage) {
                case "closed": case "precircle": case "circle": case "closing": return 60
                case "bar":    return searchH
                default:       return panelHeight
            }
        }
        radius: {
            switch (stage) {
                case "closed": case "precircle": case "circle": case "closing": return 30
                default: return 14
            }
        }
        opacity: (stage === "closed" || stage === "closing") ? 0 : 1
        color:   Colours.m3surfaceContainer

        Behavior on width   { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on height  { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on radius  { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on color   { CAnim {} }

        MouseArea { anchors.fill: parent }

        // ── Arc canvas (precircle stage) ───────────────────────────────────

        Canvas {
            id: arcCanvas
            anchors.fill: parent
            visible:      root.stage === "precircle"

            property real arcEnd: 0
            onArcEndChanged: requestPaint()

            onPaint: {
                var ctx   = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (arcEnd <= 0) return
                var cx    = width  / 2
                var cy    = height / 2
                var r     = Math.min(width, height) / 2 - 5
                var start = -Math.PI / 2
                var end   = start + (arcEnd / 360) * 2 * Math.PI
                ctx.beginPath()
                ctx.arc(cx, cy, r, start, end)
                ctx.strokeStyle = Colours.m3primary
                ctx.lineWidth   = 3
                ctx.lineCap     = "round"
                ctx.stroke()
            }
        }

        // ── App list ───────────────────────────────────────────────────────

        ListView {
            id: appList
            anchors {
                top:         parent.top
                bottom:      searchBar.top
                left:        parent.left
                right:       parent.right
                topMargin:   8
                leftMargin:  8
                rightMargin: 8
            }
            visible: root.mode === "apps"
            model:   root.mode === "apps" ? root.filtered : []
            clip:    true
            spacing: 0
            opacity: stage === "open" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            delegate: AppItem {
                required property var modelData
                required property int index
                width:          appList.width
                // Optional-chained: switching `mode` swaps this list's model
                // to/from [] reactively (see appList.model above), and a
                // delegate can briefly evaluate against an undefined
                // modelData while the ListView tears it down.
                appName:        modelData?.name        ?? ""
                appExec:        modelData?.exec         ?? ""
                appIcon:        modelData?.icon         ?? ""
                appDescription: modelData?.description  ?? ""
                showDivider:    index < appList.count - 1
                isSelected:     index === root.selectedIndex
                onHovered:      root.selectedIndex = index
                onClicked: {
                    if (!modelData) return
                    const exec = root.sanitizeExec(modelData.exec)
                    Quickshell.execDetached(["bash", "-c", exec])
                    Visibilities.toggle("launcher")
                }
            }
        }

        // ── Monitor tabs (">wallpaper" mode, only when 2+ screens) ──────────
        // "All" (activeScreen === "") targets the shared default and clears
        // every per-monitor override on commit — the sync-back-to-one-
        // wallpaper action. Picking a specific monitor scopes preview/commit
        // to just that screen (Wallpapers.currentFor/commit).

        Row {
            id: monitorTabs
            anchors {
                top:         parent.top
                left:        parent.left
                right:       parent.right
                topMargin:   8
                leftMargin:  8
                rightMargin: 8
            }
            height:  root.monitorTabsH
            spacing: 6
            visible: root.mode === "wallpapers" && Quickshell.screens.length > 1
            opacity: stage === "open" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Repeater {
                model: [""].concat(Quickshell.screens.map(s => s.name))

                delegate: Rectangle {
                    id: tab
                    required property string modelData

                    readonly property bool isSelected: root.activeScreen === tab.modelData

                    height: root.monitorTabsH
                    width:  tabLabel.implicitWidth + 20
                    radius: height / 2
                    color:  tab.isSelected ? Colours.m3primaryContainer : Colours.m3surfaceContainerHigh
                    border.width: 1
                    border.color: Colours.mid(Colours.m3surfaceContainer, tab.color)
                    Behavior on color { CAnim {} }

                    StyledText {
                        id: tabLabel
                        anchors.centerIn: parent
                        text:  tab.modelData === "" ? "All" : tab.modelData
                        color: tab.isSelected ? Colours.m3onPrimaryContainer : Colours.m3onSurfaceVariant
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.activeScreen = tab.modelData
                            root._refreshWallpaperPreview()
                        }
                    }
                }
            }
        }

        // ── Wallpaper carousel (">wallpaper" mode) ──────────────────────────
        // PathView instead of a ListView: infinite horizontal loop (Left/Right
        // wrap around both ends, no start/end stop) — PathView's currentIndex
        // wraps by default, unlike ListView. Center item is pinned via
        // highlightRangeMode + preferredHighlightBegin/End; the path's
        // itemScale/itemOpacity attributes make it bigger/fully opaque there
        // and smaller/dimmer toward the edges (lightweight coverflow look).

        PathView {
            id: wallpaperCarousel
            anchors {
                top:         monitorTabs.visible ? monitorTabs.bottom : parent.top
                bottom:      searchBar.top
                left:        parent.left
                right:       parent.right
                topMargin:   8
            }
            visible: root.mode === "wallpapers"
            model:   root.mode === "wallpapers" ? root.filtered : []
            opacity: stage === "open" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            pathItemCount: 5
            preferredHighlightBegin: 0.5
            preferredHighlightEnd:   0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            snapMode: PathView.SnapToItem

            onCurrentIndexChanged: {
                if (root.mode === "wallpapers") root.selectedIndex = currentIndex
            }

            path: Path {
                startX: 0
                startY: wallpaperCarousel.height / 2
                PathAttribute { name: "itemScale";   value: 0.72 }
                PathAttribute { name: "itemOpacity"; value: 0.45 }
                PathLine { x: wallpaperCarousel.width / 2; y: wallpaperCarousel.height / 2 }
                PathAttribute { name: "itemScale";   value: 1.0 }
                PathAttribute { name: "itemOpacity"; value: 1.0 }
                PathLine { x: wallpaperCarousel.width; y: wallpaperCarousel.height / 2 }
                PathAttribute { name: "itemScale";   value: 0.72 }
                PathAttribute { name: "itemOpacity"; value: 0.45 }
            }

            delegate: WallpaperCard {
                required property var modelData
                required property int index
                width:  130
                height: root.carouselH - 20
                scale:  PathView.itemScale
                // PathView doesn't stack the current/centered item above its
                // neighbors by default — without this, the active card's
                // right edge could render underneath the next card's left
                // edge. Bumping z for the current item keeps it fully on top.
                z: PathView.isCurrentItem ? 1 : 0
                opacity: modelData ? PathView.itemOpacity : 0
                wallName: modelData?.name ?? ""
                wallPath: modelData?.path ?? ""
                isVideo:  modelData?.isVideo ?? false
                isActive: PathView.isCurrentItem
                onHovered: if (root._wallpaperRealMove) wallpaperCarousel.currentIndex = index
                onClicked: {
                    if (!modelData) return
                    wallpaperCarousel.currentIndex = index
                    Wallpapers.commit(modelData.path, root.activeScreen)
                    Visibilities.toggle("launcher")
                }
            }
        }

        // Tracks real mouse movement over the wallpaper carousel — separate
        // from the cards' own hover/click handling (acceptedButtons: NoButton
        // means it never intercepts clicks, only observes position). See
        // root._wallpaperRealMove above for why this exists.
        MouseArea {
            id: wallpaperMoveTracker
            anchors.fill:     wallpaperCarousel
            visible:          root.mode === "wallpapers"
            hoverEnabled:     true
            acceptedButtons:  Qt.NoButton

            property bool armed: false
            property real baseX: 0
            property real baseY: 0
            readonly property real moveThreshold: 4

            onPositionChanged: {
                if (!armed) {
                    armed = true
                    baseX = mouseX
                    baseY = mouseY
                    return
                }
                if (!root._wallpaperRealMove &&
                    (Math.abs(mouseX - baseX) > moveThreshold || Math.abs(mouseY - baseY) > moveThreshold))
                    root._wallpaperRealMove = true
            }
        }

        // ── Theme mode list (">theme" mode) ─────────────────────────────────

        ListView {
            id: themeList
            anchors {
                top:         parent.top
                bottom:      searchBar.top
                left:        parent.left
                right:       parent.right
                topMargin:   8
                leftMargin:  8
                rightMargin: 8
            }
            visible: root.mode === "themes"
            model:   root.mode === "themes" ? root.filtered : []
            clip:    true
            spacing: 0
            opacity: stage === "open" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            delegate: ThemeModeItem {
                required property var modelData
                required property int index
                width:         themeList.width
                modeName:      modelData?.name ?? ""
                isActive:      modelData?.id === Colours.currentMode
                previewColors: modelData ? Colours.previewCache[modelData.id] : undefined
                isLight:       root.pendingIsLight
                showDivider:   index < themeList.count - 1
                isSelected:    index === root.selectedIndex
                onHovered:     root.selectedIndex = index
                onClicked: {
                    if (!modelData) return
                    Colours.commit(modelData.id, root.pendingIsLight)
                    Visibilities.toggle("launcher")
                }
            }
        }

        // ── Command list (bare ">" mode) ────────────────────────────────────

        ListView {
            id: commandList
            anchors {
                top:         parent.top
                bottom:      searchBar.top
                left:        parent.left
                right:       parent.right
                topMargin:   8
                leftMargin:  8
                rightMargin: 8
            }
            visible: root.mode === "commands"
            model:   root.mode === "commands" ? root.filtered : []
            clip:    true
            spacing: 0
            opacity: stage === "open" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            delegate: CommandItem {
                required property var modelData
                required property int index
                width:          commandList.width
                cmdIcon:        modelData?.icon ?? ""
                cmdName:        modelData?.name ?? ""
                cmdDescription: modelData?.description ?? ""
                showDivider:    index < commandList.count - 1
                isSelected:     index === root.selectedIndex
                onHovered:      root.selectedIndex = index
                onClicked: {
                    if (!modelData) return
                    root.pickCommand(modelData.id)
                }
            }
        }

        // ── Screensaver settings (">screensaver" mode) ──────────────────────

        ScreensaverForm {
            id: screensaverForm
            anchors {
                top:         parent.top
                bottom:      searchBar.top
                left:        parent.left
                right:       parent.right
                topMargin:   8
            }
            visible: root.mode === "screensaver"
            opacity: stage === "open" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        // ── Keybinds cheatsheet (">keybinds" mode) ──────────────────────────

        KeybindsList {
            id: keybindsList
            anchors {
                top:         parent.top
                bottom:      searchBar.top
                left:        parent.left
                right:       parent.right
                topMargin:   8
            }
            visible: root.mode === "keybinds"
            opacity: stage === "open" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        // ── Web App installer (">webapp" mode) ─────────────────────────────────

        WebAppForm {
            id: webAppForm
            anchors {
                top:         parent.top
                bottom:      searchBar.top
                left:        parent.left
                right:       parent.right
                topMargin:   8
            }
            visible: root.mode === "webapp"
            opacity: stage === "open" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        // No results placeholder
        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top:              parent.top
                topMargin:        (root.listH - font.pixelSize) / 2 + 8
            }
            // root.mode === "screensaver"/"keybinds" also have
            // filtered.length === 0 (see the `filtered` computed property
            // above) — without this, the placeholder would overlap their
            // own content any time the search text is non-empty there.
            visible:        stage === "open" && root.filtered.length === 0 &&
                             searchField.text.length > 0 &&
                             root.mode !== "screensaver" && root.mode !== "keybinds" && root.mode !== "webapp"
            text:           root.mode === "wallpapers" ? "No wallpapers found"
                            : root.mode === "themes"    ? "No themes found"
                            : root.mode === "commands"  ? "No commands found"
                            : "No apps found"
            color:          Colours.m3onSurfaceVariant
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 13
            Behavior on color { CAnim {} }
        }

        // ── Search bar (pinned to bottom) ──────────────────────────────────

        Item {
            id: searchBar
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height:  searchH
            opacity: (stage === "precircle" || stage === "circle" ||
                      stage === "closed"    || stage === "closing") ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12 }
                height:  1
                visible: stage === "open" && root.listH > 0
                color:   Qt.alpha(Colours.m3outlineVariant, 0.4)
                Behavior on color { CAnim {} }
            }

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 18 }
                text:           "󰍉"
                color:          Colours.m3onSurfaceVariant
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 16
                opacity:        stage === "open" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220 } }
                Behavior on color   { CAnim {} }
            }

            Text {
                anchors {
                    left:           parent.left
                    right:          lightDarkToggle.left
                    verticalCenter: parent.verticalCenter
                    leftMargin:     42
                    rightMargin:    8
                }
                visible: searchField.text.length === 0 && (stage === "bar" || stage === "open")
                text:           "Search apps, or type > for commands"
                color:          Colours.m3onSurfaceVariant
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 13
                Behavior on color { CAnim {} }
            }

            TextInput {
                id: searchField
                anchors {
                    left:           parent.left
                    right:          lightDarkToggle.left
                    verticalCenter: parent.verticalCenter
                    leftMargin:     42
                    rightMargin:    8
                }
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 13
                color:          Colours.m3onSurface
                selectByMouse:  true
                clip:           true
                Behavior on color { CAnim {} }

                Keys.onEscapePressed: Visibilities.toggle("launcher")
                Keys.onReturnPressed: {
                    if (root.filtered.length === 0) return
                    const idx = Math.min(root.selectedIndex, root.filtered.length - 1)
                    if (root.mode === "commands") {
                        root.pickCommand(root.filtered[idx].id)
                        return // stays open — just fills in the prefix
                    }
                    if (root.mode === "wallpapers") {
                        Wallpapers.commit(root.filtered[idx].path, root.activeScreen)
                    } else if (root.mode === "themes") {
                        Colours.commit(root.filtered[idx].id, root.pendingIsLight)
                    } else {
                        const exec = root.sanitizeExec(root.filtered[idx].exec)
                        Quickshell.execDetached(["bash", "-c", exec])
                    }
                    Visibilities.toggle("launcher")
                }
                Keys.onDownPressed: event => {
                    if (root.mode === "wallpapers") wallpaperCarousel.incrementCurrentIndex()
                    else root.selectedIndex = Math.min(root.selectedIndex + 1, root.filtered.length - 1)
                    event.accepted = true
                }
                Keys.onUpPressed: event => {
                    if (root.mode === "wallpapers") wallpaperCarousel.decrementCurrentIndex()
                    else root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                    event.accepted = true
                }
                // Left/Right only drive the carousel in wallpapers mode —
                // otherwise they need to fall through to TextInput's own
                // cursor movement while typing a query.
                Keys.onLeftPressed: event => {
                    if (root.mode === "wallpapers") {
                        wallpaperCarousel.decrementCurrentIndex()
                        event.accepted = true
                    } else {
                        event.accepted = false
                    }
                }
                Keys.onRightPressed: event => {
                    if (root.mode === "wallpapers") {
                        wallpaperCarousel.incrementCurrentIndex()
                        event.accepted = true
                    } else {
                        event.accepted = false
                    }
                }
                Keys.onTabPressed: event => {
                    if (root.mode === "themes") root.toggleLightDark()
                    event.accepted = true
                }
            }

            // Light/dark toggle — applies immediately to whichever mode is
            // currently active, instead of only taking effect the next time
            // a mode row gets clicked (that was confusing: toggling alone
            // looked like it did nothing until you also picked a mode).
            Item {
                id: lightDarkToggle
                anchors { right: clearBtn.left; verticalCenter: parent.verticalCenter; rightMargin: root.mode === "themes" ? 8 : 0 }
                width:  root.mode === "themes" ? toggleLabel.implicitWidth + 16 : 0
                height: 24
                clip:   true
                Behavior on width { NumberAnimation { duration: 150 } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.alpha(Colours.m3onSurface, 0.08)
                    visible: root.mode === "themes"
                }

                Text {
                    id: toggleLabel
                    anchors.centerIn: parent
                    text:           root.pendingIsLight ? "󰖨 Light" : "󰽥 Dark"
                    color:          Colours.m3onSurfaceVariant
                    font.family:    "Iosevka Term Nerd Font"
                    font.pixelSize: 12
                    Behavior on color { CAnim {} }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    enabled:      root.mode === "themes"
                    onClicked:    root.toggleLightDark()
                }
            }

            Item {
                id: clearBtn
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 14 }
                width: searchField.text.length > 0 ? 20 : 0
                height: 20; visible: width > 0; clip: true
                Behavior on width { NumberAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text:           "󰅖"
                    color:          Colours.m3onSurfaceVariant
                    font.family:    "Iosevka Term Nerd Font"
                    font.pixelSize: 14
                    Behavior on color { CAnim {} }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    { searchField.text = ""; searchField.forceActiveFocus() }
                }
            }
        }

        // ── Arch logo (circle stage) ───────────────────────────────────────

        Text {
            anchors.centerIn: parent
            text:           "󰣇"
            color:          Colours.m3primary
            font.family:    "Iosevka Term Nerd Font"
            font.pixelSize: 26
            opacity:        stage === "circle" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on color   { CAnim {} }
        }
    }

    // ── App loader ─────────────────────────────────────────────────────────

    Process {
        id: appsProc
        command: ["python3", Paths.scripts + "/list-apps.py"]
        stdout: SplitParser {
            onRead: line => { root._buf += line }
        }
        onRunningChanged: {
            if (running) return
            try {
                root.apps = JSON.parse(root._buf)
            } catch(e) {
                console.warn("Launcher: failed to parse app list:", e)
            }
            root._buf = ""
        }
    }
}
