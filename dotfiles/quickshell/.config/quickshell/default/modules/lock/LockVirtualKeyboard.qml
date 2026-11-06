pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.VirtualKeyboard
import QtQuick.VirtualKeyboard.Settings
import QtQuick.Window
import "../../services"

// Port of the SDDM "silent" theme's components/CVKeyboard.qml, simplified
// for this project's flatter (single-column, single-user) auth layout: the
// theme anchors "login" position against several named sibling items
// (loginLayout/loginMessage) from its own tree; here the caller just passes
// the bottom edge of its own login area via `belowY`.
//
// The theme's custom Config-driven QtQuick.VirtualKeyboard style
// (components/QtQuick/VirtualKeyboard/Styles/vkeyboardStyle/, ~1600 lines)
// is ported to assets/vkeyboard-styles/QtQuick/VirtualKeyboard/Styles/LockKeyboard/style.qml
// and selected below via VirtualKeyboardSettings.styleName. Qt resolves
// custom styles by searching the QML import path for a
// "QtQuick/VirtualKeyboard/Styles/<styleName>/style.qml" — there is no
// "QT_VIRTUALKEYBOARD_STYLESPATH" env var in Qt6 (verified against the
// installed qt6-virtualkeyboard binaries and docs, only
// "QT_VIRTUALKEYBOARD_STYLE" exists and it just selects a name, it doesn't
// add a search path). The search path itself comes from the standard Qt
// QML_IMPORT_PATH env var, which MUST be exported before `qs` starts —
// QML has no API to add import paths to an already-running engine. See
// lockscreen.md for the exact export line.
InputPanel {
    id: inputPanel

    required property Item lockSurface
    required property real belowX
    required property real belowY

    signal externalLanguageSwitchRequested()

    Component.onCompleted: VirtualKeyboardSettings.styleName = "LockKeyboard"

    width: Math.min(lockSurface.width / 2, 600) * LockConfig.virtualKeyboardScale * LockConfig.generalScale * (Screen.width / 1920)
    active: Qt.inputMethod.visible
    opacity: visible ? 1.0 : 0.0
    externalLanguageSwitchEnabled: true
    onExternalLanguageSwitch: inputPanel.externalLanguageSwitchRequested()

    property string pos: LockConfig.virtualKeyboardPosition
    property bool vKeyboardMoved: false

    x: {
        if (inputPanel.pos === "top" || inputPanel.pos === "bottom")
            return (lockSurface.width - inputPanel.width) / 2
        else if (inputPanel.pos === "left")
            return LockConfig.menuAreaButtonsMarginLeft
        else if (inputPanel.pos === "right")
            return lockSurface.width - inputPanel.width - LockConfig.menuAreaButtonsMarginRight
        // "login" — center under the actual login area (belowX is its
        // horizontal center), not the whole screen: custom.conf can anchor
        // the login area to either edge (LoginArea/position), so screen-
        // centering here would land the keyboard nowhere near the password
        // input. Clamped so it can't run off-screen when the login area
        // sits close to an edge.
        return Math.max(0, Math.min(lockSurface.width - inputPanel.width, inputPanel.belowX - inputPanel.width / 2))
    }
    y: {
        if (inputPanel.pos === "top")
            return LockConfig.menuAreaButtonsMarginTop
        else if (inputPanel.pos === "bottom")
            return lockSurface.height - inputPanel.height - LockConfig.menuAreaButtonsMarginBottom
        else if (inputPanel.pos === "left" || inputPanel.pos === "right")
            return (lockSurface.height - inputPanel.height) / 2
        if (!inputPanel.vKeyboardMoved)
            return inputPanel.belowY + LockConfig.warningMessageMarginTop
        return inputPanel.y // "login", user-dragged
    }

    MouseArea {
        id: vKeyboardDragArea
        property point initialPosition: Qt.point(-1, -1)
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        drag.target: inputPanel
        acceptedButtons: Qt.MiddleButton
        onPressed: event => {
            cursorShape = Qt.ClosedHandCursor
            initialPosition = Qt.point(event.x, event.y)
        }
        onReleased: event => {
            cursorShape = Qt.ArrowCursor
            if (initialPosition !== Qt.point(event.x, event.y) && !inputPanel.vKeyboardMoved)
                inputPanel.vKeyboardMoved = true
        }
    }
}
