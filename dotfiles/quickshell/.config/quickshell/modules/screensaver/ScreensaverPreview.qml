pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtMultimedia
import "../../services"

// Standalone preview overlay for the ">screensaver" launcher panel — shows
// exactly what the real screensaver would show, WITHOUT ever going through
// lockFromIdle()/WlSessionLock. That function is the only existing trigger
// for the screensaver visuals, and it always also sets
// WlSessionLock.locked = true — there was no way to preview the visuals
// without locking the real session before this file existed.
//
// Deliberately does NOT import or reference Lock/LockSurface/WlSessionLock
// at all, and does NOT replicate any of LockSurface's `revealed`/blur/
// brightness/saturation/theme-fallback logic — this window only ever shows
// IdleManager.effectiveScreensaverSource at full brightness. No entrance
// animation either (tried and deliberately dropped during the idle-chain
// session, see idle-screensaver.md).
//
// Same Variants/PanelWindow-per-screen skeleton as modules/background/
// Background.qml (visible on every monitor, not just the focused one — a
// screensaver blanks every display, unlike modules/launcher/Launcher.qml
// which only ever shows on the focused monitor).
Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: screenScope
        required property ShellScreen modelData

        PanelWindow {
            id: win
            screen: screenScope.modelData
            color:  "black"

            visible: Visibilities.screensaverPreview

            WlrLayershell.layer:         WlrLayer.Overlay
            WlrLayershell.namespace:     "deadlock-screensaver-preview"
            WlrLayershell.exclusiveZone: -1
            // Exclusive only while shown — released immediately on dismiss,
            // same pattern as modules/launcher/Launcher.qml.
            WlrLayershell.keyboardFocus: Visibilities.screensaverPreview
                                         ? WlrKeyboardFocus.Exclusive
                                         : WlrKeyboardFocus.None

            anchors { top: true; bottom: true; left: true; right: true }

            readonly property string source:  IdleManager.effectiveScreensaverSource
            readonly property bool   isVideo: Wallpapers.isVideoPath(win.source)

            // A PanelWindow (unlike WlSessionLockSurface) needs its own
            // focused Item for Keys.onPressed to actually fire — confirmed
            // against modules/bar/Osd.qml's identical `Item { anchors.fill;
            // focus: true; Keys.onEscapePressed }` pattern, the other place
            // in the project that captures keys from a plain PanelWindow.
            Item {
                id: focusCatcher
                anchors.fill: parent
                focus: Visibilities.screensaverPreview

                Keys.onPressed: event => {
                    Visibilities.screensaverPreview = false
                    event.accepted = true
                }

                Image {
                    anchors.fill: parent
                    visible:      !win.isVideo && win.source !== ""
                    source:       (!win.isVideo && win.source !== "") ? ("file://" + win.source) : ""
                    fillMode:     Image.PreserveAspectCrop
                    asynchronous: true
                    smooth:       true
                    mipmap:       true
                }

                Video {
                    id: previewVideo
                    anchors.fill: parent
                    visible:  win.isVideo && win.source !== ""
                    source:   (win.isVideo && win.source !== "") ? ("file://" + win.source) : ""
                    autoPlay: win.isVideo && win.source !== ""
                    loops:    MediaPlayer.Infinite
                    muted:    true
                    fillMode: VideoOutput.PreserveAspectCrop
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked:    Visibilities.screensaverPreview = false
                }
            }
        }
    }
}
