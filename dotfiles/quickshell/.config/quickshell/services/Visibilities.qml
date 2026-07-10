pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property bool launcher:      false
    property bool dashboard:     false
    property bool calendar:      false
    property bool notifications: false
    property bool volume:         false
    property bool batteryProfile: false
    property bool notifToast:     false
    property bool silentMode:     false
    property bool trayMenu:       false
    property bool recorderModeOsd: false
    property bool powerMenu:       false
    // Independent overlay, NOT part of `panels`/closeAll() below — it's not
    // mutually exclusive with the launcher (ScreensaverForm's preview button
    // shows it ON TOP of the still-open launcher), so it's set directly by
    // callers instead of going through toggle().
    property bool screensaverPreview: false

    property real volumeBarCenterX:  0
    property real batteryBarCenterX: 0
    // Center X of whichever tray icon was right-clicked (not the whole
    // BgAppsWidget pill) — set right before toggling trayMenu.
    property real trayMenuIconX: 0
    // The StatusNotifierItem (services/../modules/bar/BgAppsWidget.qml
    // Repeater's modelData) whose .menu the popup should render.
    property var  trayMenuTarget: null
    // Center X of RecorderWidget, same mapToItem trick as trayMenuIconX —
    // set right before toggling recorderModeOsd.
    property real recorderOsdCenterX: 0

    function toggle(name) {
        const panels = ["launcher", "dashboard", "calendar", "notifications", "volume", "batteryProfile", "trayMenu", "recorderModeOsd", "powerMenu"]
        for (let i = 0; i < panels.length; i++) {
            if (panels[i] !== name) root[panels[i]] = false
        }
        root[name] = !root[name]
    }

    function closeAll() {
        launcher = dashboard = calendar = notifications = volume = batteryProfile = trayMenu = recorderModeOsd = powerMenu = false
    }
}
