pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../services"

// Shared per-screen popup chrome for the bar's simple toggle OSDs (battery
// profile, recorder mode, tray menu) — one focused-monitor-only PanelWindow
// per screen, top-anchored 44px below the bar, matugen palette already
// resolved via Colours.paletteFor.
//
// Each OSD supplies its card/content as `content: Component { Item {
// anchors.fill: parent; property PanelWindow win: null; property var osd:
// null; ... } }`. Instantiated via createObject (not Loader) with win/osd
// passed as initial properties, so they're already in place before the
// content's own bindings evaluate for the first time — win.colors/
// win.width etc. work immediately, matugen hot-reload included, and `osd`
// lets content reach back into functions the outer OSD file exposes on
// itself (e.g. BatteryProfileOsd's pauseAutoClose()).
//
// The show/hide timer + Visibilities.* Connections are NOT abstracted here
// — deliberately left to each OSD file, added as extra children of this
// component. They differ too much to be worth forcing into one shape
// (Osd.qml — volume/brightness — has two independent flows plus per-screen
// positioning math, which is why it isn't built on this wrapper at all).
//
// Root is a plain Item (not the Variants directly) so those extra children
// (Timer, Connections, plain properties) are ordinary Item children instead
// of landing in Variants' default property — Variants treats everything
// there as part of its per-model delegate expansion and tries to inject
// modelData into it, which broke Timer/Connections construction entirely.
Item {
    id: root

    property string    namespace:  ""
    property int       osdHeight:  60
    property bool      osdVisible: false
    property Component content:    null

    Variants {
        model: Quickshell.screens

        delegate: Scope {
            id: screenScope
            required property ShellScreen modelData

            PanelWindow {
                id: win
                screen: screenScope.modelData
                color:  "transparent"

                readonly property bool isFocused:
                    screenScope.modelData.name === (Hyprland.focusedMonitor?.name ?? "")
                // Per-monitor palette (bar/panels only — see Colours.paletteFor).
                readonly property var colors: Colours.paletteFor(screenScope.modelData.name)

                visible: isFocused && root.osdVisible

                WlrLayershell.layer:         WlrLayer.Top
                WlrLayershell.namespace:     root.namespace
                WlrLayershell.exclusiveZone: -1
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                anchors { top: true; left: true; right: true }
                margins.top:    44
                implicitHeight: root.osdHeight

                Component.onCompleted: {
                    if (root.content) root.content.createObject(win.contentItem, { win: win, osd: root })
                }
            }
        }
    }
}
