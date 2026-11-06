pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils"

// Reads the SDDM "silent" theme's .conf files (INI format) unchanged and
// exposes the same property names as the theme's own components/Config.qml,
// so modules/lock/assets/configs/*.conf never need to be edited.
Singleton {
    id: root

    property var cfg: ({})

    FileView {
        id: confFile
        path: `${Paths.lockConfigDir}/${Paths.activeLockConfig}.conf`
        watchChanges: true
        onTextChanged: root.parse(confFile.text())
    }

    function parse(text) {
        if (!text || text.length === 0) return
        const out = {}
        let section = ""
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (line.length === 0 || line.startsWith(";") || line.startsWith("#")) continue
            const sectionMatch = line.match(/^\[(.+)\]$/)
            if (sectionMatch) {
                section = sectionMatch[1]
                continue
            }
            const eq = line.indexOf("=")
            if (eq === -1) continue
            const key = line.slice(0, eq).trim()
            const value = line.slice(eq + 1).trim()
            out[`${section}/${key}`] = value
        }
        root.cfg = out
    }

    function stringValue(key) {
        const v = root.cfg[key]
        if (v === undefined) return ""
        const s = String(v)
        if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) return s.slice(1, -1)
        return s
    }

    function intValue(key) {
        const n = parseInt(root.cfg[key], 10)
        return isNaN(n) ? 0 : n
    }

    function realValue(key) {
        const n = parseFloat(root.cfg[key])
        return isNaN(n) ? 0.0 : n
    }

    function boolValue(key) {
        return root.cfg[key] === "true"
    }

    // Lets a .conf reference a live matugen role (e.g. "m3primary") instead
    // of a hex literal for accent/focus colors — Colours.palette lookups
    // read here are tracked as binding dependencies same as any other
    // property, so these colors update live on wallpaper/theme changes with
    // no lockscreen restart needed. Falls through to the raw string (a
    // normal hex color, or "" for fallback) when it's not a known role.
    function colorValue(key, fallback) {
        const raw = root.stringValue(key)
        if (raw === "") return fallback
        const paletteColor = Colours.palette[raw]
        return paletteColor !== undefined ? paletteColor : raw
    }

    // [General] — accessed without section prefix in the original theme;
    // here we keep the "General/" prefix since we control both sides.
    property real generalScale: root.realValue("General/scale") || 1.0
    property bool enableAnimations: root.cfg["General/enable-animations"] === "false" ? false : true
    property string animatedBackgroundPlaceholder: root.stringValue("General/animated-background-placeholder")
    property string backgroundFillMode: root.stringValue("General/background-fill-mode") || "fill"

    // [LockScreen]
    property bool lockScreenDisplay: root.cfg["LockScreen/display"] === "false" ? false : true
    property int lockScreenPaddingTop: root.intValue("LockScreen/padding-top")
    property int lockScreenPaddingRight: root.intValue("LockScreen/padding-right")
    property int lockScreenPaddingBottom: root.intValue("LockScreen/padding-bottom")
    property int lockScreenPaddingLeft: root.intValue("LockScreen/padding-left")
    property string lockScreenBackground: root.stringValue("LockScreen/background") || "default.jpg"
    property bool lockScreenUseBackgroundColor: root.boolValue("LockScreen/use-background-color")
    property color lockScreenBackgroundColor: root.stringValue("LockScreen/background-color") || "#000000"
    property int lockScreenBlur: root.intValue("LockScreen/blur")
    property real lockScreenBrightness: root.realValue("LockScreen/brightness")
    property real lockScreenSaturation: root.realValue("LockScreen/saturation")

    // [LockScreen.Clock]
    property bool clockDisplay: root.cfg["LockScreen.Clock/display"] === "false" ? false : true
    property string clockPosition: root.stringValue("LockScreen.Clock/position") || "top-center"
    property string clockAlign: root.stringValue("LockScreen.Clock/align") || "center"
    property string clockFormat: root.stringValue("LockScreen.Clock/format") || "hh:mm"
    property string clockFontFamily: root.stringValue("LockScreen.Clock/font-family") || "RedHatDisplay"
    property int clockFontSize: root.intValue("LockScreen.Clock/font-size") || 70
    property int clockFontWeight: root.intValue("LockScreen.Clock/font-weight") || 900
    property color clockColor: root.stringValue("LockScreen.Clock/color") || "#FFFFFF"

    // [LockScreen.Date]
    property bool dateDisplay: root.cfg["LockScreen.Date/display"] === "false" ? false : true
    property string dateFormat: root.stringValue("LockScreen.Date/format") || "dddd, MMMM dd, yyyy"
    property string dateLocale: root.stringValue("LockScreen.Date/locale") || "en_US"
    property string dateFontFamily: root.stringValue("LockScreen.Date/font-family") || "RedHatDisplay"
    property int dateFontSize: root.intValue("LockScreen.Date/font-size") || 14
    property int dateFontWeight: root.intValue("LockScreen.Date/font-weight") || 400
    property color dateColor: root.colorValue("LockScreen.Date/color", "#FFFFFF")
    property int dateMarginTop: root.intValue("LockScreen.Date/margin-top")

    // [LockScreen.Message]
    property bool lockMessageDisplay: root.cfg["LockScreen.Message/display"] === "false" ? false : true
    property string lockMessagePosition: root.stringValue("LockScreen.Message/position") || "bottom-center"
    property string lockMessageAlign: root.stringValue("LockScreen.Message/align") || "center"
    property string lockMessageText: root.stringValue("LockScreen.Message/text") || "Press any key"
    property string lockMessageFontFamily: root.stringValue("LockScreen.Message/font-family") || "RedHatDisplay"
    property int lockMessageFontSize: root.intValue("LockScreen.Message/font-size") || 12
    property int lockMessageFontWeight: root.intValue("LockScreen.Message/font-weight") || 400
    property bool lockMessageDisplayIcon: root.cfg["LockScreen.Message/display-icon"] === "false" ? false : true
    property string lockMessageIcon: root.stringValue("LockScreen.Message/icon") || "enter.svg"
    property int lockMessageIconSize: root.intValue("LockScreen.Message/icon-size") || 16
    property color lockMessageColor: root.stringValue("LockScreen.Message/color") || "#FFFFFF"
    property bool lockMessagePaintIcon: root.cfg["LockScreen.Message/paint-icon"] === "false" ? false : true
    property int lockMessageSpacing: root.intValue("LockScreen.Message/spacing")

    // [LoginScreen]
    property string loginScreenBackground: root.stringValue("LoginScreen/background") || "default.jpg"
    property bool loginScreenUseBackgroundColor: root.boolValue("LoginScreen/use-background-color")
    property color loginScreenBackgroundColor: root.stringValue("LoginScreen/background-color") || "#000000"
    property int loginScreenBlur: root.intValue("LoginScreen/blur")
    property real loginScreenBrightness: root.realValue("LoginScreen/brightness")
    property real loginScreenSaturation: root.realValue("LoginScreen/saturation")

    // [LoginScreen.LoginArea]
    property string loginAreaPosition: root.stringValue("LoginScreen.LoginArea/position") || "center"
    property int loginAreaMargin: root.intValue("LoginScreen.LoginArea/margin")

    // [LoginScreen.LoginArea.Avatar]
    property string avatarShape: root.stringValue("LoginScreen.LoginArea.Avatar/shape") || "circle"
    property int avatarBorderRadius: root.intValue("LoginScreen.LoginArea.Avatar/border-radius")
    property int avatarActiveSize: root.intValue("LoginScreen.LoginArea.Avatar/active-size") || 120
    property int avatarInactiveSize: root.intValue("LoginScreen.LoginArea.Avatar/inactive-size") || 80
    property real avatarInactiveOpacity: root.realValue("LoginScreen.LoginArea.Avatar/inactive-opacity") || 0.35
    property int avatarActiveBorderSize: root.intValue("LoginScreen.LoginArea.Avatar/active-border-size")
    property int avatarInactiveBorderSize: root.intValue("LoginScreen.LoginArea.Avatar/inactive-border-size")
    property color avatarActiveBorderColor: root.stringValue("LoginScreen.LoginArea.Avatar/active-border-color") || "#FFFFFF"
    property color avatarInactiveBorderColor: root.stringValue("LoginScreen.LoginArea.Avatar/inactive-border-color") || "#FFFFFF"

    // [LoginScreen.LoginArea.Username]
    property string usernameFontFamily: root.stringValue("LoginScreen.LoginArea.Username/font-family") || "RedHatDisplay"
    property int usernameFontSize: root.intValue("LoginScreen.LoginArea.Username/font-size") || 16
    property int usernameFontWeight: root.intValue("LoginScreen.LoginArea.Username/font-weight") || 900
    property color usernameColor: root.stringValue("LoginScreen.LoginArea.Username/color") || "#FFFFFF"
    property int usernameMargin: root.intValue("LoginScreen.LoginArea.Username/margin")

    // [LoginScreen.LoginArea.PasswordInput]
    property int passwordInputWidth: root.intValue("LoginScreen.LoginArea.PasswordInput/width") || 200
    property int passwordInputHeight: root.intValue("LoginScreen.LoginArea.PasswordInput/height") || 30
    property bool passwordInputDisplayIcon: root.cfg["LoginScreen.LoginArea.PasswordInput/display-icon"] === "false" ? false : true
    property string passwordInputFontFamily: root.stringValue("LoginScreen.LoginArea.PasswordInput/font-family") || "RedHatDisplay"
    property int passwordInputFontSize: root.intValue("LoginScreen.LoginArea.PasswordInput/font-size") || 12
    property string passwordInputIcon: root.stringValue("LoginScreen.LoginArea.PasswordInput/icon") || "password.svg"
    property int passwordInputIconSize: root.intValue("LoginScreen.LoginArea.PasswordInput/icon-size") || 16
    property color passwordInputContentColor: root.colorValue("LoginScreen.LoginArea.PasswordInput/content-color", "#FFFFFF")
    property color passwordInputBackgroundColor: root.colorValue("LoginScreen.LoginArea.PasswordInput/background-color", "#FFFFFF")
    property real passwordInputBackgroundOpacity: root.realValue("LoginScreen.LoginArea.PasswordInput/background-opacity")
    property int passwordInputBorderSize: root.intValue("LoginScreen.LoginArea.PasswordInput/border-size")
    property color passwordInputBorderColor: root.stringValue("LoginScreen.LoginArea.PasswordInput/border-color") || "#FFFFFF"
    property int passwordInputBorderRadiusLeft: root.intValue("LoginScreen.LoginArea.PasswordInput/border-radius-left")
    property int passwordInputBorderRadiusRight: root.intValue("LoginScreen.LoginArea.PasswordInput/border-radius-right")
    property int passwordInputMarginTop: root.intValue("LoginScreen.LoginArea.PasswordInput/margin-top")
    property string passwordInputMaskedCharacter: root.stringValue("LoginScreen.LoginArea.PasswordInput/masked-character") || "●"

    // [LoginScreen.LoginArea.LoginButton]
    property color loginButtonBackgroundColor: root.colorValue("LoginScreen.LoginArea.LoginButton/background-color", "#FFFFFF")
    property real loginButtonBackgroundOpacity: root.realValue("LoginScreen.LoginArea.LoginButton/background-opacity")
    property color loginButtonActiveBackgroundColor: root.colorValue("LoginScreen.LoginArea.LoginButton/active-background-color", "#FFFFFF")
    property real loginButtonActiveBackgroundOpacity: root.realValue("LoginScreen.LoginArea.LoginButton/active-background-opacity")
    property string loginButtonIcon: root.stringValue("LoginScreen.LoginArea.LoginButton/icon") || "arrow-right.svg"
    property int loginButtonIconSize: root.intValue("LoginScreen.LoginArea.LoginButton/icon-size") || 18
    property color loginButtonContentColor: root.colorValue("LoginScreen.LoginArea.LoginButton/content-color", "#FFFFFF")
    property color loginButtonActiveContentColor: root.colorValue("LoginScreen.LoginArea.LoginButton/active-content-color", "#FFFFFF")
    property int loginButtonBorderSize: root.intValue("LoginScreen.LoginArea.LoginButton/border-size")
    property color loginButtonBorderColor: root.stringValue("LoginScreen.LoginArea.LoginButton/border-color") || "#FFFFFF"
    property int loginButtonBorderRadiusLeft: root.intValue("LoginScreen.LoginArea.LoginButton/border-radius-left")
    property int loginButtonBorderRadiusRight: root.intValue("LoginScreen.LoginArea.LoginButton/border-radius-right")
    property int loginButtonMarginLeft: root.intValue("LoginScreen.LoginArea.LoginButton/margin-left")
    property bool loginButtonShowTextIfNoPassword: root.cfg["LoginScreen.LoginArea.LoginButton/show-text-if-no-password"] === "false" ? false : true
    property bool loginButtonHideIfNotNeeded: root.boolValue("LoginScreen.LoginArea.LoginButton/hide-if-not-needed")
    property string loginButtonFontFamily: root.stringValue("LoginScreen.LoginArea.LoginButton/font-family") || "RedHatDisplay"
    property int loginButtonFontSize: root.intValue("LoginScreen.LoginArea.LoginButton/font-size") || 12
    property int loginButtonFontWeight: root.intValue("LoginScreen.LoginArea.LoginButton/font-weight") || 600

    // [LoginScreen.LoginArea.Spinner]
    property bool spinnerDisplayText: root.cfg["LoginScreen.LoginArea.Spinner/display-text"] === "false" ? false : true
    property string spinnerText: root.stringValue("LoginScreen.LoginArea.Spinner/text") || "Logging in"
    property string spinnerFontFamily: root.stringValue("LoginScreen.LoginArea.Spinner/font-family") || "RedHatDisplay"
    property int spinnerFontWeight: root.intValue("LoginScreen.LoginArea.Spinner/font-weight") || 600
    property int spinnerFontSize: root.intValue("LoginScreen.LoginArea.Spinner/font-size") || 12
    property int spinnerIconSize: root.intValue("LoginScreen.LoginArea.Spinner/icon-size") || 32
    property string spinnerIcon: root.stringValue("LoginScreen.LoginArea.Spinner/icon") || "spinner.svg"
    property color spinnerColor: root.stringValue("LoginScreen.LoginArea.Spinner/color") || "#FFFFFF"
    property int spinnerSpacing: root.intValue("LoginScreen.LoginArea.Spinner/spacing")

    // [LoginScreen.LoginArea.WarningMessage]
    property string warningMessageFontFamily: root.stringValue("LoginScreen.LoginArea.WarningMessage/font-family") || "RedHatDisplay"
    property int warningMessageFontSize: root.intValue("LoginScreen.LoginArea.WarningMessage/font-size") || 11
    property int warningMessageFontWeight: root.intValue("LoginScreen.LoginArea.WarningMessage/font-weight") || 400
    property color warningMessageNormalColor: root.stringValue("LoginScreen.LoginArea.WarningMessage/normal-color") || "#FFFFFF"
    property color warningMessageWarningColor: root.stringValue("LoginScreen.LoginArea.WarningMessage/warning-color") || "#FFFFFF"
    property color warningMessageErrorColor: root.stringValue("LoginScreen.LoginArea.WarningMessage/error-color") || "#FFFFFF"
    property int warningMessageMarginTop: root.intValue("LoginScreen.LoginArea.WarningMessage/margin-top")

    // [LoginScreen.MenuArea.Buttons]
    property int menuAreaButtonsMarginTop: root.intValue("LoginScreen.MenuArea.Buttons/margin-top")
    property int menuAreaButtonsMarginRight: root.intValue("LoginScreen.MenuArea.Buttons/margin-right")
    property int menuAreaButtonsMarginBottom: root.intValue("LoginScreen.MenuArea.Buttons/margin-bottom")
    property int menuAreaButtonsMarginLeft: root.intValue("LoginScreen.MenuArea.Buttons/margin-left")
    property int menuAreaButtonsSize: root.intValue("LoginScreen.MenuArea.Buttons/size") || 30
    property int menuAreaButtonsBorderRadius: root.intValue("LoginScreen.MenuArea.Buttons/border-radius")
    property int menuAreaButtonsSpacing: root.intValue("LoginScreen.MenuArea.Buttons/spacing")
    property string menuAreaButtonsFontFamily: root.stringValue("LoginScreen.MenuArea.Buttons/font-family") || "RedHatDisplay"

    // [LoginScreen.MenuArea.Popups]
    property int menuAreaPopupsMaxHeight: root.intValue("LoginScreen.MenuArea.Popups/max-height") || 300
    property int menuAreaPopupsItemHeight: root.intValue("LoginScreen.MenuArea.Popups/item-height") || 30
    property int menuAreaPopupsSpacing: root.intValue("LoginScreen.MenuArea.Popups/item-spacing")
    property int menuAreaPopupsPadding: root.intValue("LoginScreen.MenuArea.Popups/padding")
    property bool menuAreaPopupsDisplayScrollbar: root.cfg["LoginScreen.MenuArea.Popups/display-scrollbar"] === "false" ? false : true
    property int menuAreaPopupsMargin: root.intValue("LoginScreen.MenuArea.Popups/margin")
    property color menuAreaPopupsBackgroundColor: root.stringValue("LoginScreen.MenuArea.Popups/background-color") || "#FFFFFF"
    property real menuAreaPopupsBackgroundOpacity: root.realValue("LoginScreen.MenuArea.Popups/background-opacity")
    property color menuAreaPopupsActiveOptionBackgroundColor: root.colorValue("LoginScreen.MenuArea.Popups/active-option-background-color", "#FFFFFF")
    property real menuAreaPopupsActiveOptionBackgroundOpacity: root.realValue("LoginScreen.MenuArea.Popups/active-option-background-opacity")
    property color menuAreaPopupsContentColor: root.stringValue("LoginScreen.MenuArea.Popups/content-color") || "#FFFFFF"
    property color menuAreaPopupsActiveContentColor: root.colorValue("LoginScreen.MenuArea.Popups/active-content-color", "#FFFFFF")
    property string menuAreaPopupsFontFamily: root.stringValue("LoginScreen.MenuArea.Popups/font-family") || "RedHatDisplay"
    property int menuAreaPopupsBorderSize: root.intValue("LoginScreen.MenuArea.Popups/border-size")
    property color menuAreaPopupsBorderColor: root.stringValue("LoginScreen.MenuArea.Popups/border-color") || "#FFFFFF"
    property int menuAreaPopupsFontSize: root.intValue("LoginScreen.MenuArea.Popups/font-size") || 11
    property int menuAreaPopupsIconSize: root.intValue("LoginScreen.MenuArea.Popups/icon-size") || 16

    // [LoginScreen.MenuArea.Layout]
    property bool layoutDisplay: root.cfg["LoginScreen.MenuArea.Layout/display"] === "false" ? false : true
    property string layoutPosition: root.stringValue("LoginScreen.MenuArea.Layout/position")
    property int layoutIndex: root.intValue("LoginScreen.MenuArea.Layout/index")
    property string layoutPopupDirection: root.stringValue("LoginScreen.MenuArea.Layout/popup-direction") || "up"
    property string layoutPopupAlign: root.stringValue("LoginScreen.MenuArea.Layout/popup-align") || "center"
    property int layoutPopupWidth: root.intValue("LoginScreen.MenuArea.Layout/popup-width") || 180
    property bool layoutDisplayLayoutName: root.cfg["LoginScreen.MenuArea.Layout/display-layout-name"] === "false" ? false : true
    property color layoutBackgroundColor: root.stringValue("LoginScreen.MenuArea.Layout/background-color") || "#FFFFFF"
    property real layoutBackgroundOpacity: root.realValue("LoginScreen.MenuArea.Layout/background-opacity")
    property real layoutActiveBackgroundOpacity: root.realValue("LoginScreen.MenuArea.Layout/active-background-opacity")
    property color layoutContentColor: root.stringValue("LoginScreen.MenuArea.Layout/content-color") || "#FFFFFF"
    property color layoutActiveContentColor: root.colorValue("LoginScreen.MenuArea.Layout/active-content-color", "#FFFFFF")
    property int layoutBorderSize: root.intValue("LoginScreen.MenuArea.Layout/border-size")
    property int layoutFontSize: root.intValue("LoginScreen.MenuArea.Layout/font-size") || 10
    property string layoutIcon: root.stringValue("LoginScreen.MenuArea.Layout/icon") || "language.svg"
    property int layoutIconSize: root.intValue("LoginScreen.MenuArea.Layout/icon-size") || 16

    // [LoginScreen.MenuArea.Keyboard]
    property bool keyboardDisplay: root.cfg["LoginScreen.MenuArea.Keyboard/display"] === "false" ? false : true
    property string keyboardPosition: root.stringValue("LoginScreen.MenuArea.Keyboard/position")
    property int keyboardIndex: root.intValue("LoginScreen.MenuArea.Keyboard/index")
    property color keyboardBackgroundColor: root.stringValue("LoginScreen.MenuArea.Keyboard/background-color") || "#FFFFFF"
    property real keyboardBackgroundOpacity: root.realValue("LoginScreen.MenuArea.Keyboard/background-opacity")
    property real keyboardActiveBackgroundOpacity: root.realValue("LoginScreen.MenuArea.Keyboard/active-background-opacity")
    property color keyboardContentColor: root.stringValue("LoginScreen.MenuArea.Keyboard/content-color") || "#FFFFFF"
    property color keyboardActiveContentColor: root.colorValue("LoginScreen.MenuArea.Keyboard/active-content-color", "#FFFFFF")
    property int keyboardBorderSize: root.intValue("LoginScreen.MenuArea.Keyboard/border-size")
    property string keyboardIcon: root.stringValue("LoginScreen.MenuArea.Keyboard/icon") || "keyboard.svg"
    property int keyboardIconSize: root.intValue("LoginScreen.MenuArea.Keyboard/icon-size") || 16

    // [LoginScreen.MenuArea.Power]
    property bool powerDisplay: root.cfg["LoginScreen.MenuArea.Power/display"] === "false" ? false : true
    property string powerPosition: root.stringValue("LoginScreen.MenuArea.Power/position")
    property int powerIndex: root.intValue("LoginScreen.MenuArea.Power/index")
    property string powerPopupDirection: root.stringValue("LoginScreen.MenuArea.Power/popup-direction") || "up"
    property string powerPopupAlign: root.stringValue("LoginScreen.MenuArea.Power/popup-align") || "center"
    property int powerPopupWidth: root.intValue("LoginScreen.MenuArea.Power/popup-width") || 90
    property color powerBackgroundColor: root.stringValue("LoginScreen.MenuArea.Power/background-color") || "#FFFFFF"
    property real powerBackgroundOpacity: root.realValue("LoginScreen.MenuArea.Power/background-opacity")
    property real powerActiveBackgroundOpacity: root.realValue("LoginScreen.MenuArea.Power/active-background-opacity")
    property color powerContentColor: root.stringValue("LoginScreen.MenuArea.Power/content-color") || "#FFFFFF"
    property color powerActiveContentColor: root.colorValue("LoginScreen.MenuArea.Power/active-content-color", "#FFFFFF")
    property int powerBorderSize: root.intValue("LoginScreen.MenuArea.Power/border-size")
    property string powerIcon: root.stringValue("LoginScreen.MenuArea.Power/icon") || "power.svg"
    property int powerIconSize: root.intValue("LoginScreen.MenuArea.Power/icon-size") || 16

    // [LoginScreen.VirtualKeyboard]
    property real virtualKeyboardScale: root.realValue("LoginScreen.VirtualKeyboard/scale") || 1.0
    property string virtualKeyboardPosition: root.stringValue("LoginScreen.VirtualKeyboard/position") || "login"
    property bool virtualKeyboardStartHidden: root.cfg["LoginScreen.VirtualKeyboard/start-hidden"] === "false" ? false : true
    property color virtualKeyboardBackgroundColor: root.stringValue("LoginScreen.VirtualKeyboard/background-color") || "#FFFFFF"
    property real virtualKeyboardBackgroundOpacity: root.realValue("LoginScreen.VirtualKeyboard/background-opacity")
    property color virtualKeyboardKeyContentColor: root.stringValue("LoginScreen.VirtualKeyboard/key-content-color") || "#FFFFFF"
    property color virtualKeyboardKeyColor: root.stringValue("LoginScreen.VirtualKeyboard/key-color") || "#FFFFFF"
    property real virtualKeyboardKeyOpacity: root.realValue("LoginScreen.VirtualKeyboard/key-opacity")
    property color virtualKeyboardKeyActiveBackgroundColor: root.colorValue("LoginScreen.VirtualKeyboard/key-active-background-color", "#FFFFFF")
    property real virtualKeyboardKeyActiveOpacity: root.realValue("LoginScreen.VirtualKeyboard/key-active-opacity")
    property color virtualKeyboardSelectionBackgroundColor: root.colorValue("LoginScreen.VirtualKeyboard/selection-background-color", "#CCCCCC")
    property color virtualKeyboardSelectionContentColor: root.colorValue("LoginScreen.VirtualKeyboard/selection-content-color", "#FFFFFF")
    property color virtualKeyboardPrimaryColor: root.colorValue("LoginScreen.VirtualKeyboard/primary-color", "#000000")
    property int virtualKeyboardBorderSize: root.intValue("LoginScreen.VirtualKeyboard/border-size")
    property color virtualKeyboardBorderColor: root.stringValue("LoginScreen.VirtualKeyboard/border-color") || "#000000"

    // [Tooltips]
    property bool tooltipsEnable: root.cfg["Tooltips/enable"] === "false" ? false : true
    property string tooltipsFontFamily: root.stringValue("Tooltips/font-family") || "RedHatDisplay"
    property int tooltipsFontSize: root.intValue("Tooltips/font-size") || 11
    property color tooltipsContentColor: root.stringValue("Tooltips/content-color") || "#FFFFFF"
    property color tooltipsBackgroundColor: root.stringValue("Tooltips/background-color") || "#FFFFFF"
    property real tooltipsBackgroundOpacity: root.realValue("Tooltips/background-opacity")
    property int tooltipsBorderRadius: root.intValue("Tooltips/border-radius") || 5
    property bool tooltipsDisableUser: root.boolValue("Tooltips/disable-user")
    property bool tooltipsDisableLoginButton: root.boolValue("Tooltips/disable-login-button")

    function sortMenuButtons() {
        const menus = []
        const availablePositions = ["top-left", "top-center", "top-right", "center-left", "center-right", "bottom-left", "bottom-center", "bottom-right"]

        if (root.layoutDisplay)
            menus.push({
                name: "layout",
                index: root.layoutIndex,
                def_index: 1,
                position: availablePositions.includes(root.layoutPosition) ? root.layoutPosition : "bottom-right"
            })

        if (root.keyboardDisplay)
            menus.push({
                name: "keyboard",
                index: root.keyboardIndex,
                def_index: 2,
                position: availablePositions.includes(root.keyboardPosition) ? root.keyboardPosition : "bottom-right"
            })

        if (root.powerDisplay)
            menus.push({
                name: "power",
                index: root.powerIndex,
                def_index: 3,
                position: availablePositions.includes(root.powerPosition) ? root.powerPosition : "bottom-right"
            })

        return menus.sort((a, b) => a.index - b.index || a.def_index - b.def_index)
    }

    function getIcon(iconName) {
        const extArr = iconName.split(".")
        const ext = extArr.length > 1 ? extArr[extArr.length - 1] : ""
        return `${Paths.lockIconsDir}/${iconName}${ext === "" ? ".svg" : ""}`
    }
}
