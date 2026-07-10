pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import "../../services"

// Port of the SDDM "silent" theme's components/PowerMenu.qml.
// sddm.canSuspend/canReboot/canPowerOff have no Quickshell equivalent, so
// MVP leaves all three always enabled (same precedent as
// modules/dashboard/ProfileSection.qml's power row). sddm.suspend/reboot/
// powerOff() -> systemctl via Quickshell.execDetached(), same precedent.
ColumnLayout {
    id: selector

    width: LockConfig.powerPopupWidth * LockConfig.generalScale * (Screen.width / 1920)
    spacing: 2

    signal closeRequested()

    KeyNavigation.up: shutdownButton
    KeyNavigation.down: suspendButton

    LockIconButton {
        id: suspendButton
        Layout.preferredHeight: LockConfig.menuAreaPopupsItemHeight * LockConfig.generalScale * (Screen.width / 1920)
        Layout.preferredWidth: LockConfig.powerPopupWidth * LockConfig.generalScale * (Screen.width / 1920)
        preferredWidth: Layout.preferredWidth
        focus: selector.visible
        icon: LockConfig.getIcon("power-suspend.svg")
        contentColor: LockConfig.menuAreaPopupsContentColor
        activeContentColor: LockConfig.menuAreaPopupsActiveContentColor
        fontFamily: LockConfig.menuAreaPopupsFontFamily
        backgroundColor: "transparent"
        activeBackgroundColor: LockConfig.menuAreaPopupsActiveOptionBackgroundColor
        activeBackgroundOpacity: LockConfig.menuAreaPopupsActiveOptionBackgroundOpacity
        iconSize: LockConfig.menuAreaPopupsIconSize
        fontSize: LockConfig.menuAreaPopupsFontSize
        label: "Suspend"
        onClicked: {
            selector.closeRequested()
            Quickshell.execDetached(["systemctl", "suspend"])
        }

        KeyNavigation.up: shutdownButton
        KeyNavigation.down: rebootButton
    }

    LockIconButton {
        id: rebootButton
        Layout.preferredHeight: LockConfig.menuAreaPopupsItemHeight * LockConfig.generalScale * (Screen.width / 1920)
        Layout.preferredWidth: LockConfig.powerPopupWidth * LockConfig.generalScale * (Screen.width / 1920)
        preferredWidth: Layout.preferredWidth
        focus: selector.visible
        icon: LockConfig.getIcon("power-reboot.svg")
        contentColor: LockConfig.menuAreaPopupsContentColor
        activeContentColor: LockConfig.menuAreaPopupsActiveContentColor
        fontFamily: LockConfig.menuAreaPopupsFontFamily
        backgroundColor: "transparent"
        activeBackgroundColor: LockConfig.menuAreaPopupsActiveOptionBackgroundColor
        activeBackgroundOpacity: LockConfig.menuAreaPopupsActiveOptionBackgroundOpacity
        iconSize: LockConfig.menuAreaPopupsIconSize
        fontSize: LockConfig.menuAreaPopupsFontSize
        label: "Reboot"
        onClicked: {
            selector.closeRequested()
            Quickshell.execDetached(["systemctl", "reboot"])
        }

        KeyNavigation.up: suspendButton
        KeyNavigation.down: shutdownButton
    }

    LockIconButton {
        id: shutdownButton
        Layout.preferredHeight: LockConfig.menuAreaPopupsItemHeight * LockConfig.generalScale * (Screen.width / 1920)
        Layout.preferredWidth: LockConfig.powerPopupWidth * LockConfig.generalScale * (Screen.width / 1920)
        preferredWidth: Layout.preferredWidth
        focus: selector.visible
        icon: LockConfig.getIcon("power.svg")
        contentColor: LockConfig.menuAreaPopupsContentColor
        activeContentColor: LockConfig.menuAreaPopupsActiveContentColor
        fontFamily: LockConfig.menuAreaPopupsFontFamily
        backgroundColor: "transparent"
        activeBackgroundColor: LockConfig.menuAreaPopupsActiveOptionBackgroundColor
        activeBackgroundOpacity: LockConfig.menuAreaPopupsActiveOptionBackgroundOpacity
        iconSize: LockConfig.menuAreaPopupsIconSize
        fontSize: LockConfig.menuAreaPopupsFontSize
        label: "Shut down"
        onClicked: {
            selector.closeRequested()
            Quickshell.execDetached(["systemctl", "poweroff"])
        }

        KeyNavigation.up: rebootButton
        KeyNavigation.down: suspendButton
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
            selector.closeRequested()
    }
}
