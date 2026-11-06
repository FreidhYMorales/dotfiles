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
    // Fingerprint runs independently of authState/password — it's a
    // passive background listener, not a blocking "authenticating" step,
    // so it never disables the password field. listening | success | error
    property string fingerprintState: "listening"

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
        if (root.focus) {
            root.resetFocus()
            // Security.fingerprintEnabled (">security" in the launcher) —
            // when off, pamFingerprint is simply never started, same as if
            // the feature didn't exist. It's still declared/instantiated
            // below; only .start() calls are gated, so there's nothing to
            // tear down/recreate here.
            if (Security.fingerprintEnabled && !pamFingerprint.start()) fingerprintRestart.restart()
        } else {
            if (pamFingerprint.active) pamFingerprint.abort()
        }
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
        // NOT "passwd": that service `include`s system-auth, whose auth
        // stack starts with `auth sufficient pam_fprintd.so timeout=4` —
        // every attempt here would silently run an up-to-4s fingerprint
        // check FIRST (delaying the real password check behind it), and a
        // sensor touch during that window could unlock with NO password
        // check at all, bypassing the ">security" toggle entirely (that
        // toggle only gates pamFingerprint below, not this system-wide
        // stack). "quickshell-password" (system/pam.d/quickshell-password)
        // is system-auth's own auth section minus that one line — see
        // auditorias/autenticacion/README.md §11.
        config: "quickshell-password"
        user: root.userName

        onResponseRequiredChanged: {
            if (pam.responseRequired) pam.respond(passwordInput.text)
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                // Guarded the same way pamFingerprint's own onCompleted
                // already guards `pam.abort()` below — this side just never
                // needed it before, because pamFingerprint used to always be
                // started unconditionally. Now that Security.fingerprintEnabled
                // (">security") can skip starting it entirely, this branch
                // could call .abort() on a PamContext that was never active,
                // which threw and skipped the `locked = false` line right
                // after it.
                if (pamFingerprint.active) pamFingerprint.abort()
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

    // Runs in parallel with the password PamContext above, independent
    // conversation via a dedicated fprintd-only PAM service (no pam_unix —
    // see system/pam.d/quickshell-fprint) — either one unlocking wins,
    // matching the same either/or pattern GDM uses (see
    // auditorias/autenticacion/README.md §7.2/§9.4: PAM serializes a single
    // conversation, so a real dual-factor listen requires two independent
    // PamContexts, not two modules in one PAM stack). Auto-(re)started on
    // reveal via onFocusChanged above.
    PamContext {
        id: pamFingerprint
        config: "quickshell-fprint"
        user: root.userName

        onResponseRequiredChanged: {
            if (pamFingerprint.responseRequired) pamFingerprint.respond("")
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.fingerprintState = "success"
                if (pam.active) pam.abort()
                root.lock.locked = false
            } else {
                // max-tries=1 in quickshell-fprint means a single bad swipe
                // completes immediately (see the PAM service's own comment)
                // — restart a fresh conversation right away so a correct
                // touch right after a bad one isn't stuck waiting.
                root.fingerprintState = "error"
                fingerprintRestart.restart()
            }
        }

        onError: () => {
            root.fingerprintState = "error"
            fingerprintRestart.restart()
        }
    }

    // Restarting too soon after a failed scan can hit fprintd while it's
    // still tearing down the previous conversation's device claim —
    // confirmed live: `fprintd: Authorization denied ... Device was already
    // claimed`. When that happens, start() returns false synchronously and
    // no completed()/error() signal ever fires for it, so a naive
    // "restart once" dead-ends here permanently. Fix: check start()'s own
    // return value and keep retrying on this timer until it actually
    // claims the device, instead of assuming one retry is always enough.
    //
    // Deliberately NOT gated on root.focus: confirmed live (extensive
    // session debugging with tagged console.log across LockAuth/LockSurface)
    // that root.focus can read false here even though the user never left
    // the auth screen — nothing pressed, nothing else able to steal focus
    // under Wayland's session-lock protocol. Root cause not identified
    // (reads like a QtQuick focus-property quirk, not a real reveal/hide —
    // LockSurface.revealed itself never changed when this happened), but
    // gating on it was the actual bug: it made a wrong-finger touch
    // silently kill the retry loop until something unrelated (like a
    // password attempt) happened to re-trigger onFocusChanged. abort() in
    // onFocusChanged's else branch is the real "stop" signal for this
    // listener now; retrying unconditionally here is safe even if focus
    // happens to read wrong, since a stray successful unlock while the
    // screen is genuinely hidden isn't harmful.
    Timer {
        id: fingerprintRestart
        interval: 300
        onTriggered: {
            if (!Security.fingerprintEnabled) return
            root.fingerprintState = "listening"
            if (!pamFingerprint.start()) fingerprintRestart.restart()
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
                id: fingerprintIcon
                // Hardcoded, not Style.fontFamily: modules/lock/ deliberately
                // doesn't depend on the main shell's Colours/Style singletons
                // (its own LockConfig.qml is the theming source here — see
                // docs/services.md#styleqml) — DepartureMono Nerd Font is
                // still what's installed system-wide (bootstrap.sh step 22),
                // just referenced directly instead of through Style.
                readonly property string iconFontFamily: "DepartureMono Nerd Font"

                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.topMargin: LockConfig.passwordInputMarginTop
                horizontalAlignment: Text.AlignHCenter
                visible: root.authState !== "authenticating" && Security.fingerprintEnabled
                font.family: fingerprintIcon.iconFontFamily
                font.pixelSize: (root.fingerprintState === "listening" ? 50 : 100) * LockConfig.generalScale * (Screen.width / 1920)
                text: String.fromCodePoint(0xf0237) // md-fingerprint (Nerd Fonts)
                color: root.fingerprintState === "success" ? LockConfig.loginButtonActiveContentColor
                    : root.fingerprintState === "error" ? LockConfig.warningMessageErrorColor
                    : LockConfig.warningMessageNormalColor

                Behavior on font.pixelSize {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: 180 }
                }

                // "Actively scanning" breathing pulse — only while idle/listening,
                // not during success/error (those are answers, not activity).
                // Same enableAnimations gate LockSpinner.qml uses for its own
                // RotationAnimation, for consistency.
                SequentialAnimation {
                    id: scanPulse
                    running: root.fingerprintState === "listening" && LockConfig.enableAnimations
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) fingerprintIcon.opacity = 1

                    NumberAnimation {
                        target: fingerprintIcon
                        property: "opacity"
                        from: 1.0
                        to: 0.35
                        duration: 900
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: fingerprintIcon
                        property: "opacity"
                        from: 0.35
                        to: 1.0
                        duration: 900
                        easing.type: Easing.InOutSine
                    }
                }
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
