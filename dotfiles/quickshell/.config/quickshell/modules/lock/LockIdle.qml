pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window
import "../../services"

// Idle screen shown before the password field is revealed — port of the
// SDDM "silent" theme's components/LockScreen.qml.
Item {
    id: root

    signal loginRequested()

    // When false (screensaver-over-lock, see LockSurface.qml's
    // useScreensaverBg), hides the clock/date/message so only the raw
    // screensaver image/video shows — the click/key capture below stays
    // active either way, so the first touch still reveals the password
    // prompt.
    property bool contentVisible: true

    readonly property var knownPositions: [
        "top-left", "top-center", "top-right",
        "center-left", "center", "center-right",
        "bottom-left", "bottom-center", "bottom-right"
    ]

    // default.conf ships a malformed value (`"bottom"-center`) for
    // LockScreen.Message/position — validate against the known enum instead
    // of trusting the raw config string, so a typo upstream degrades to the
    // documented default instead of LockSurface's bottom-right fallback.
    function safePosition(pos, fallback) {
        return root.knownPositions.includes(pos) ? pos : fallback
    }

    function alignItem(item, pos) {
        // Clear every line first — this runs more than once now (alignPos is
        // reactive, see below), and each case below only sets 2 of the 6
        // lines. Without clearing, a stale line from the previous call (e.g.
        // "top" from the pre-config-load default) stays anchored alongside
        // the new ones, producing a conflicting/stretched layout instead of
        // just moving to the right spot.
        item.anchors.top = undefined
        item.anchors.bottom = undefined
        item.anchors.left = undefined
        item.anchors.right = undefined
        item.anchors.horizontalCenter = undefined
        item.anchors.verticalCenter = undefined

        switch (pos) {
        case "top-left":
            item.anchors.top = root.top
            item.anchors.left = root.left
            break
        case "top-center":
            item.anchors.top = root.top
            item.anchors.horizontalCenter = root.horizontalCenter
            break
        case "top-right":
            item.anchors.top = root.top
            item.anchors.right = root.right
            break
        case "center-left":
            item.anchors.verticalCenter = root.verticalCenter
            item.anchors.left = root.left
            break
        case "center":
            item.anchors.verticalCenter = root.verticalCenter
            item.anchors.horizontalCenter = root.horizontalCenter
            break
        case "center-right":
            item.anchors.verticalCenter = root.verticalCenter
            item.anchors.right = root.right
            break
        case "bottom-left":
            item.anchors.bottom = root.bottom
            item.anchors.left = root.left
            break
        case "bottom-center":
            item.anchors.bottom = root.bottom
            item.anchors.horizontalCenter = root.horizontalCenter
            break
        default:
            item.anchors.bottom = root.bottom
            item.anchors.right = root.right
        }
    }

    ColumnLayout {
        id: timePositioner
        visible: root.contentVisible
        spacing: LockConfig.dateMarginTop

        // LockConfig loads its .conf asynchronously — alignPos re-evaluates
        // once the real value replaces the fallback default, re-running
        // alignItem() instead of getting stuck with whatever Component.onCompleted
        // saw first (see the identical race fixed in LockAuth.qml's loginContainer).
        readonly property string alignPos: root.safePosition(LockConfig.clockPosition, "top-center")
        onAlignPosChanged: root.alignItem(timePositioner, alignPos)

        Text {
            id: time
            visible: LockConfig.clockDisplay
            font.pixelSize: LockConfig.clockFontSize * LockConfig.generalScale * (Screen.width / 1920)
            font.weight: LockConfig.clockFontWeight
            font.family: LockConfig.clockFontFamily
            color: LockConfig.clockColor
            Layout.alignment: LockConfig.clockAlign === "left" ? Qt.AlignLeft : (LockConfig.clockAlign === "right" ? Qt.AlignRight : Qt.AlignHCenter)

            function updateTime() {
                time.text = new Date().toLocaleString(Qt.locale(LockConfig.dateLocale), LockConfig.clockFormat)
            }
        }

        Text {
            id: date
            visible: LockConfig.dateDisplay
            font.pixelSize: LockConfig.dateFontSize * LockConfig.generalScale * (Screen.width / 1920)
            font.family: LockConfig.dateFontFamily
            font.weight: LockConfig.dateFontWeight
            color: LockConfig.dateColor
            Layout.alignment: LockConfig.clockAlign === "left" ? Qt.AlignLeft : (LockConfig.clockAlign === "right" ? Qt.AlignRight : Qt.AlignHCenter)

            function updateDate() {
                date.text = new Date().toLocaleString(Qt.locale(LockConfig.dateLocale), LockConfig.dateFormat)
            }
        }

        Timer {
            interval: 1000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: {
                time.updateTime()
                date.updateDate()
            }
        }

        anchors {
            topMargin: LockConfig.lockScreenPaddingTop || (root.height > 0 ? root.height / 10 : 50)
            rightMargin: LockConfig.lockScreenPaddingRight || (root.height > 0 ? root.height / 10 : 50)
            bottomMargin: LockConfig.lockScreenPaddingBottom || (root.height > 0 ? root.height / 10 : 50)
            leftMargin: LockConfig.lockScreenPaddingLeft || (root.height > 0 ? root.height / 10 : 50)
        }

        Component.onCompleted: {
            root.alignItem(timePositioner, alignPos)
            time.updateTime()
            date.updateDate()
        }
    }

    ColumnLayout {
        id: messagePositioner
        visible: LockConfig.lockMessageDisplay && root.contentVisible
        spacing: LockConfig.lockMessageSpacing

        readonly property string alignPos: root.safePosition(LockConfig.lockMessagePosition, "bottom-center")
        onAlignPosChanged: root.alignItem(messagePositioner, alignPos)

        Item {
            Layout.alignment: LockConfig.lockMessageAlign === "left" ? Qt.AlignLeft : (LockConfig.lockMessageAlign === "right" ? Qt.AlignRight : Qt.AlignHCenter)
            Layout.preferredWidth: LockConfig.lockMessageIconSize
            Layout.preferredHeight: LockConfig.lockMessageIconSize

            Image {
                id: lockIcon
                source: `file://${LockConfig.getIcon(LockConfig.lockMessageIcon)}`
                width: LockConfig.lockMessageIconSize * LockConfig.generalScale * (Screen.width / 1920)
                height: width
                sourceSize: Qt.size(width, height)
                fillMode: Image.PreserveAspectFit
                visible: false
            }
            MultiEffect {
                source: lockIcon
                anchors.fill: lockIcon
                colorization: LockConfig.lockMessagePaintIcon ? 1 : 0
                colorizationColor: LockConfig.lockMessageColor
                visible: LockConfig.lockMessageDisplayIcon
                antialiasing: true
            }
        }

        Text {
            id: lockMessage
            Layout.alignment: LockConfig.lockMessageAlign === "left" ? Qt.AlignLeft : (LockConfig.lockMessageAlign === "right" ? Qt.AlignRight : Qt.AlignHCenter)
            font.pixelSize: LockConfig.lockMessageFontSize * LockConfig.generalScale * (Screen.width / 1920)
            font.family: LockConfig.lockMessageFontFamily
            font.weight: LockConfig.lockMessageFontWeight
            color: LockConfig.lockMessageColor
            text: LockConfig.lockMessageText
        }

        anchors {
            topMargin: LockConfig.lockScreenPaddingTop || (root.height > 0 ? root.height / 10 : 50)
            rightMargin: LockConfig.lockScreenPaddingRight || (root.height > 0 ? root.height / 10 : 50)
            bottomMargin: LockConfig.lockScreenPaddingBottom || (root.height > 0 ? root.height / 10 : 50)
            leftMargin: LockConfig.lockScreenPaddingLeft || (root.height > 0 ? root.height / 10 : 50)
        }

        Component.onCompleted: root.alignItem(messagePositioner, alignPos)
    }

    MouseArea {
        id: idleMouseArea
        hoverEnabled: true
        z: -1
        anchors.fill: root
        // Blank while screensaver-only (see contentVisible) so the cursor
        // doesn't give away the lock is already active — any movement at
        // all (not just a click) reveals the password prompt, matching how
        // a real screensaver dismisses.
        cursorShape: root.contentVisible ? Qt.ArrowCursor : Qt.BlankCursor
        onClicked: root.loginRequested()

        // The first positionChanged after this surface maps isn't real
        // movement — Wayland sends a pointer "enter" event with the
        // cursor's current position as soon as the lock surface becomes
        // focused, and MouseArea reports that the same as a move. Without
        // this baseline, the screensaver never got a chance to show: it
        // reported "movement" and revealed the password prompt instantly.
        // A few pixels of slack — tiny jitter from hover/pointer polling
        // (not a deliberate move) was tripping loginRequested() within a
        // fraction of a second of locking, unlocking the session again
        // almost instantly and making it look like the grace period never
        // elapsed (it did — the "free dismiss" branch just kept re-firing).
        readonly property real moveThreshold: 4
        property bool armed: false
        property real baseX: 0
        property real baseY: 0
        onPositionChanged: {
            if (!armed) {
                armed = true
                baseX = mouseX
                baseY = mouseY
                return
            }
            if (Math.abs(mouseX - baseX) > moveThreshold || Math.abs(mouseY - baseY) > moveThreshold)
                root.loginRequested()
        }
    }

    // Re-arm the movement baseline every time the screensaver-only state
    // (re)starts, so a stale position from a previous lock cycle can't
    // falsely count as "already moved" next time.
    onContentVisibleChanged: if (!contentVisible) idleMouseArea.armed = false

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            event.accepted = false
            return
        }
        root.loginRequested()
        event.accepted = true
    }
}
