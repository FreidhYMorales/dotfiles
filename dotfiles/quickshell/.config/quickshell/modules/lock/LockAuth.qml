pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../../services"

// Avatar + password input + PAM auth, revealed on top of LockIdle. Port of
// the SDDM "silent" theme's components/LoginScreen.qml, simplified for a
// single user (no UserSelector/SessionSelector — see lockscreen plan).
Item {
    id: root

    required property WlSessionLock lock

    signal closeRequested()

    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""
    property string authState: "normal" // normal | authenticating
    property bool showKeyboard: !LockConfig.virtualKeyboardStartHidden

    // "left"/"right" put the avatar beside the username+password column
    // instead of above it (see silvia.conf/rei.conf) — this drives both the
    // info column's Layout.alignment and its anchor relationship to avatar.
    readonly property int columnAlignment: LockConfig.loginAreaPosition === "left" ? Qt.AlignLeft
        : LockConfig.loginAreaPosition === "right" ? Qt.AlignRight
        : Qt.AlignHCenter

    function login() {
        if (root.authState === "authenticating") return
        if (passwordInput.text.length === 0) return
        root.authState = "authenticating"
        pam.start()
    }

    function resetFocus() {
        passwordInput.input.forceActiveFocus()
    }

    // `focus` is toggled from LockSurface (focus: root.revealed) every time
    // this screen is shown — Component.onCompleted only fires once at
    // creation, so without this the TextField never actually gets active
    // focus on reveal and stray keys (e.g. the one that woke the idle
    // screen) can fall through and fire an empty submit.
    onFocusChanged: {
        if (root.focus) root.resetFocus()
    }

    function reset() {
        root.authState = "normal"
        passwordInput.text = ""
        loginMessage.clear()
        root.resetFocus()
    }

    onAuthStateChanged: {
        if (root.authState === "normal") root.resetFocus()
    }

    // Each PAM attempt is a fresh conversation: start() begins it,
    // responseRequiredChanged signals when a response (the typed password)
    // must be sent, and completed() ends that attempt — Failed/MaxTries do
    // NOT keep the context usable, a new start() is required to retry
    // (confirmed against the real libpam backend before writing this).
    PamContext {
        id: pam
        config: "passwd"
        user: root.userName

        onResponseRequiredChanged: {
            if (pam.responseRequired) pam.respond(passwordInput.text)
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.lock.locked = false
            } else {
                root.authState = "normal"
                passwordInput.text = ""
                loginMessage.warn(result === PamResult.MaxTries ? "Too many attempts" : "Login failed", "error")
            }
        }

        onError: () => {
            root.authState = "normal"
            passwordInput.text = ""
            loginMessage.warn("Authentication error", "error")
        }
    }

    // GridLayout instead of a plain Item with hand-computed width/height and
    // anchors between avatar/infoColumn: those manual formulas (Math.max/sum
    // of avatar+infoColumn sizes) proved unreliable across the
    // loginAreaPosition transition on a cold start — live debug logging
    // showed loginContainer.height freezing at 0 right when posCenter flipped
    // false, even though avatar.height/infoColumn.implicitHeight were both
    // confirmed non-zero at that exact instant (childrenRect had the same
    // problem earlier). GridLayout computes its own implicit size from
    // children natively, so there's no manual formula left to get stuck.
    GridLayout {
        id: loginContainer

        // Live bindings instead of Component.onCompleted: LockConfig loads its
        // .conf asynchronously (FileView), and onCompleted only runs once — on
        // a cold shell start it could fire before the config finished loading,
        // baking in the wrong branch for this WlSessionLockSurface's lifetime
        // (only self-corrected once the singleton was already warm, e.g. the
        // next lock cycle). Reactive bindings re-evaluate whenever
        // LockConfig.loginAreaPosition/loginAreaMargin actually change, so
        // there's no race to lose.
        readonly property bool posLeft: LockConfig.loginAreaPosition === "left"
        readonly property bool posRight: LockConfig.loginAreaPosition === "right"
        readonly property bool posCenter: !posLeft && !posRight
        readonly property bool centered: LockConfig.loginAreaMargin === -1

        // "left"/"right": avatar beside the column, 1 row x 2 columns.
        // "center": avatar above the column, 2 rows x 1 column.
        columns: posCenter ? 1 : 2
        rowSpacing: posCenter ? LockConfig.usernameMargin : 0
        columnSpacing: posCenter ? 0 : LockConfig.usernameMargin

        // LoginScreen.LoginArea/position + /margin. "center" (default)
        // pins the whole block by centering/top-anchoring against `root`;
        // "left"/"right" pins it to that edge instead (default-left.conf /
        // default-right.conf).
        anchors.verticalCenter: !(posCenter && !centered) ? root.verticalCenter : undefined
        anchors.horizontalCenter: (posCenter || centered) ? root.horizontalCenter : undefined
        anchors.left: (posLeft && !centered) ? root.left : undefined
        anchors.leftMargin: LockConfig.loginAreaMargin
        anchors.right: (posRight && !centered) ? root.right : undefined
        anchors.rightMargin: LockConfig.loginAreaMargin
        anchors.top: (posCenter && !centered) ? root.top : undefined
        anchors.topMargin: LockConfig.loginAreaMargin

        LockAvatar {
            id: avatar
            tooltipText: root.userName
            Layout.row: 0
            Layout.column: loginContainer.posRight ? 1 : 0
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            // avatar is a plain Rectangle with its own width/height binding
            // (not implicitWidth/Height) — GridLayout needs this explicit
            // hint to count it in loginContainer.implicitHeight's row-size
            // calculation (confirmed live: without it, implicitHeight
            // undercounted this row).
            Layout.preferredWidth: avatar.width
            Layout.preferredHeight: avatar.height
        }

        ColumnLayout {
            id: infoColumn
            spacing: 0
            Layout.row: loginContainer.posCenter ? 1 : 0
            Layout.column: loginContainer.posLeft ? 1 : 0
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: activeUserName
                Layout.alignment: root.columnAlignment
                font.family: LockConfig.usernameFontFamily
                font.weight: LockConfig.usernameFontWeight
                font.pixelSize: LockConfig.usernameFontSize * LockConfig.generalScale * (Screen.width / 1920)
                color: LockConfig.usernameColor
                text: root.userName
            }

            RowLayout {
                id: loginArea
                Layout.alignment: root.columnAlignment
                Layout.topMargin: LockConfig.passwordInputMarginTop
                height: LockConfig.passwordInputHeight * LockConfig.generalScale * (Screen.width / 1920)
                spacing: LockConfig.loginButtonMarginLeft
                visible: root.authState !== "authenticating"

                LockPasswordInput {
                    id: passwordInput
                    Layout.alignment: Qt.AlignVCenter
                    enabled: root.authState === "normal"
                    icon: LockConfig.getIcon(LockConfig.passwordInputIcon)
                    placeholder: "Password"
                    isPassword: true
                    splitBorderRadius: true
                    onAccepted: root.login()
                }

                LockIconButton {
                    id: loginButton
                    Layout.alignment: Qt.AlignVCenter
                    height: passwordInput.height
                    visible: !LockConfig.loginButtonHideIfNotNeeded
                    enabled: root.authState !== "authenticating"
                    activeFocusOnTab: true
                    icon: LockConfig.getIcon(LockConfig.loginButtonIcon)
                    label: "Login"
                    showLabel: false
                    tooltipText: !LockConfig.tooltipsDisableLoginButton ? "Login" : ""
                    iconSize: LockConfig.loginButtonIconSize
                    fontFamily: LockConfig.loginButtonFontFamily
                    fontSize: LockConfig.loginButtonFontSize
                    fontWeight: LockConfig.loginButtonFontWeight
                    contentColor: LockConfig.loginButtonContentColor
                    activeContentColor: LockConfig.loginButtonActiveContentColor
                    backgroundColor: LockConfig.loginButtonBackgroundColor
                    backgroundOpacity: LockConfig.loginButtonBackgroundOpacity
                    activeBackgroundColor: LockConfig.loginButtonActiveBackgroundColor
                    activeBackgroundOpacity: LockConfig.loginButtonActiveBackgroundOpacity
                    borderSize: LockConfig.loginButtonBorderSize
                    borderColor: LockConfig.loginButtonBorderColor
                    borderRadiusLeft: LockConfig.loginButtonBorderRadiusLeft
                    borderRadiusRight: LockConfig.loginButtonBorderRadiusRight
                    onClicked: root.login()
                }
            }

            LockSpinner {
                id: spinner
                Layout.alignment: root.columnAlignment
                Layout.topMargin: LockConfig.passwordInputMarginTop
                visible: root.authState === "authenticating"
            }

            Text {
                id: loginMessage
                Layout.alignment: root.columnAlignment
                Layout.topMargin: visible ? LockConfig.warningMessageMarginTop : 0
                font.pixelSize: LockConfig.warningMessageFontSize * LockConfig.generalScale * (Screen.width / 1920)
                font.family: LockConfig.warningMessageFontFamily
                font.weight: LockConfig.warningMessageFontWeight
                color: LockConfig.warningMessageNormalColor
                visible: text !== "" && root.authState !== "authenticating"

                function warn(message, type) {
                    loginMessage.text = message
                    loginMessage.color = type === "error" ? LockConfig.warningMessageErrorColor
                        : type === "warning" ? LockConfig.warningMessageWarningColor
                        : LockConfig.warningMessageNormalColor
                }

                function clear() {
                    loginMessage.text = ""
                }
            }
        }
    }

    LockMenuArea {
        anchors.fill: parent
        authState: root.authState
        showKeyboard: root.showKeyboard
        onToggleKeyboardRequested: root.showKeyboard = !root.showKeyboard
    }

    LockVirtualKeyboard {
        lockSurface: root
        // loginContainer.width/height (not implicitWidth/implicitHeight)
        // are unreliable here: this GridLayout's own internal geometry
        // management overrides any external write to height (confirmed
        // live — even an explicit `height: implicitHeight` binding on it
        // got silently reset back to 0), so read implicitWidth/Height
        // directly instead, which stayed correct throughout every test.
        belowX: loginContainer.x + loginContainer.implicitWidth / 2
        belowY: loginContainer.y + loginContainer.implicitHeight
        visible: root.showKeyboard && root.authState !== "authenticating"
        onExternalLanguageSwitchRequested: {} // no cross-popup handle to the layout selector yet
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            if (root.authState === "authenticating") {
                event.accepted = true
                return
            }
            root.reset()
            root.closeRequested()
            event.accepted = true
            return
        }
        event.accepted = false
    }
}
