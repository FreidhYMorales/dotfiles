pragma ComponentBehavior: Bound

import QtQuick
import "../../services"
import "../../components"
import "../../components/controls"

// ">screensaver" launcher content — sliders/toggle write straight to
// IdleManager, same "no pending state" contract Osd.qml's own volume/
// brightness sliders already use (Audio.setVolume() is called immediately,
// there's no separate "save" step). Plain Column, not a ListView/PathView —
// this mode doesn't participate in the launcher's selectedIndex/keyboard
// navigation (mouse-only, same as Osd.qml's sliders).
//
// The mini wallpaper picker below deliberately never calls
// Wallpapers.preview()/commit() — those drive the REAL desktop wallpaper
// (modules/background/Background.qml binds to Wallpapers.current), and
// touching them here would flicker the live desktop just from browsing this
// picker. It writes directly to IdleManager.screensaverPath instead.
Item {
    id: root

    readonly property bool showWallpaperPicker: !IdleManager.screensaverUseWallpaper

    // Fixed-constant sizing (same criterion as LauncherContent.qml's
    // carouselH) rather than implicitHeight auto-layout, so the parent's
    // listH computation stays a simple lookup.
    readonly property int baseFormH:   252
    readonly property int pickerFormH: baseFormH + 150
    readonly property int formH: root.showWallpaperPicker ? root.pickerFormH : root.baseFormH

    function timeoutLabel(v) {
        return v <= 0 ? "Disabled" : (v + " min")
    }

    // Same hover-movement guard as LauncherContent.qml's wallpaperCarousel —
    // a newly-mapped/newly-visible surface reports the cursor's current
    // (possibly stationary) position as a synthetic "enter", which looks
    // identical to a real hover. Re-armed both when the launcher (re)opens
    // and whenever this mini-picker becomes visible (toggling the switch
    // mid-session reveals it without the launcher itself reopening).
    property bool _wallpaperRealMove: false

    function _rearmWallpaperGuard() {
        root._wallpaperRealMove = false
        wallpaperMoveTracker.armed = false
    }

    Connections {
        target: Visibilities
        function onLauncherChanged() {
            if (Visibilities.launcher) root._rearmWallpaperGuard()
        }
    }

    onShowWallpaperPickerChanged: if (root.showWallpaperPicker) root._rearmWallpaperGuard()

    Column {
        anchors {
            left:        parent.left
            right:       parent.right
            top:         parent.top
            topMargin:   8
            leftMargin:  16
            rightMargin: 16
        }
        spacing: 12

        // ── Screensaver timeout ─────────────────────────────────────────
        Item {
            width:  parent.width
            height: 40

            Text {
                anchors { left: parent.left; top: parent.top }
                text:           "Screensaver — " + root.timeoutLabel(IdleManager.screensaverTimeoutMin)
                color:          Colours.m3onSurface
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 13
                Behavior on color { CAnim {} }
            }

            Slider {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 24
                min:    0
                max:    60
                step:   1
                value:  IdleManager.screensaverTimeoutMin
                onMoved: v => IdleManager.screensaverTimeoutMin = v
            }
        }

        // ── Lock timeout ────────────────────────────────────────────────
        Item {
            width:  parent.width
            height: 40

            Text {
                anchors { left: parent.left; top: parent.top }
                text:           "Lock — " + root.timeoutLabel(IdleManager.lockTimeoutMin)
                color:          Colours.m3onSurface
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 13
                Behavior on color { CAnim {} }
            }

            Slider {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 24
                min:    0
                max:    60
                step:   1
                value:  IdleManager.lockTimeoutMin
                onMoved: v => IdleManager.lockTimeoutMin = v
            }
        }

        // ── Suspend timeout ─────────────────────────────────────────────
        Item {
            width:  parent.width
            height: 40

            Text {
                anchors { left: parent.left; top: parent.top }
                text:           "Suspend — " + root.timeoutLabel(IdleManager.suspendTimeoutMin)
                color:          Colours.m3onSurface
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 13
                Behavior on color { CAnim {} }
            }

            Slider {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 24
                min:    0
                max:    120
                step:   1
                value:  IdleManager.suspendTimeoutMin
                onMoved: v => IdleManager.suspendTimeoutMin = v
            }
        }

        // ── Use desktop wallpaper toggle ────────────────────────────────
        Item {
            width:  parent.width
            height: 28

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text:           "Same as desktop wallpaper"
                color:          Colours.m3onSurface
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 13
                Behavior on color { CAnim {} }
            }

            Toggle {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                checked:  IdleManager.screensaverUseWallpaper
                onToggled: c => IdleManager.screensaverUseWallpaper = c
            }
        }

        // ── Mini wallpaper picker (only when NOT using the desktop one) ──
        Item {
            width:   parent.width
            height:  140
            visible: root.showWallpaperPicker

            PathView {
                id: screensaverWallCarousel
                anchors.fill: parent
                model:   root.showWallpaperPicker ? Wallpapers.entries : []

                // Same pathItemCount as LauncherContent.qml's ">wallpaper"
                // carousel (wallpaperCarousel) — with the same path width,
                // fewer items means more visual gap between neighbors. This
                // was 3, spreading cards out much more than the main picker.
                pathItemCount: 5
                preferredHighlightBegin: 0.5
                preferredHighlightEnd:   0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                snapMode: PathView.SnapToItem

                path: Path {
                    startX: 0
                    startY: screensaverWallCarousel.height / 2
                    PathAttribute { name: "itemScale";   value: 0.72 }
                    PathAttribute { name: "itemOpacity"; value: 0.45 }
                    PathLine { x: screensaverWallCarousel.width / 2; y: screensaverWallCarousel.height / 2 }
                    PathAttribute { name: "itemScale";   value: 1.0 }
                    PathAttribute { name: "itemOpacity"; value: 1.0 }
                    PathLine { x: screensaverWallCarousel.width; y: screensaverWallCarousel.height / 2 }
                    PathAttribute { name: "itemScale";   value: 0.72 }
                    PathAttribute { name: "itemOpacity"; value: 0.45 }
                }

                delegate: WallpaperCard {
                    required property var modelData
                    required property int index
                    width:    100
                    height:   110
                    scale:    PathView.itemScale
                    // Same stacking fix as LauncherContent.qml's wallpaperCarousel
                    // — keeps the centered card's edge from rendering under its
                    // neighbor's edge.
                    z: PathView.isCurrentItem ? 1 : 0
                    opacity:  modelData ? PathView.itemOpacity : 0
                    wallName: modelData?.name ?? ""
                    wallPath: modelData?.path ?? ""
                    isVideo:  modelData?.isVideo ?? false
                    isActive: modelData?.path === IdleManager.screensaverPath
                    onHovered: if (root._wallpaperRealMove) screensaverWallCarousel.currentIndex = index
                    onClicked: {
                        if (!modelData) return
                        screensaverWallCarousel.currentIndex = index
                        IdleManager.screensaverPath = modelData.path
                    }
                }
            }

            // Tracks real mouse movement over this mini-picker — see
            // root._wallpaperRealMove above for why this exists.
            MouseArea {
                id: wallpaperMoveTracker
                anchors.fill:    screensaverWallCarousel
                hoverEnabled:    true
                acceptedButtons: Qt.NoButton

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
        }

        // ── Preview button ──────────────────────────────────────────────
        // Plain Rectangle+Text+MouseArea pill, matching the launcher's own
        // light/dark toggle pill (LauncherContent.qml's lightDarkToggle
        // block, ~lines 555-586) rather than IconButton (icon-only, no
        // text-label variant).
        //
        // Deliberately sets the property directly instead of calling
        // Visibilities.toggle("screensaverPreview") — toggle() closes every
        // OTHER name in its `panels` array, and since "screensaverPreview"
        // isn't a member of that array, every single one of those panels
        // (including "launcher" itself) would get force-closed as a side
        // effect. That contradicts the preview being an overlay that shows
        // ON TOP of the still-open launcher.
        Item {
            width:  previewLabel.implicitWidth + 32
            height: 32
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color:  Qt.alpha(Colours.m3onSurface, 0.08)
            }

            Text {
                id: previewLabel
                anchors.centerIn: parent
                text:           "󰈈  Preview"
                color:          Colours.m3onSurfaceVariant
                font.family:    "Iosevka Term Nerd Font"
                font.pixelSize: 12
                Behavior on color { CAnim {} }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    Visibilities.screensaverPreview = !Visibilities.screensaverPreview
            }
        }
    }
}
