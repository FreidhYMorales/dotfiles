pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.VirtualKeyboard.Settings
import QtQuick.Window
import "../../services"

// Port of the SDDM "silent" theme's components/MenuArea.qml, scoped to
// Power + Layout + Keyboard (no Session — single-user lockscreen, see
// lockscreen plan). LockConfig.sortMenuButtons() already excludes "session"
// entirely.
Item {
    id: menuArea
    anchors.fill: parent

    // authState is forwarded from LockAuth so button `enabled` bindings can
    // mirror the theme's `loginScreen.state === "normal" || popup.visible`.
    required property string authState
    required property bool showKeyboard

    signal toggleKeyboardRequested()

    Component {
        id: keyboardMenuComponent

        LockIconButton {
            height: LockConfig.menuAreaButtonsSize * LockConfig.generalScale * (Screen.width / 1920)
            width: LockConfig.menuAreaButtonsSize * LockConfig.generalScale * (Screen.width / 1920)
            icon: LockConfig.getIcon(LockConfig.keyboardIcon)
            iconSize: LockConfig.keyboardIconSize
            backgroundColor: LockConfig.keyboardBackgroundColor
            backgroundOpacity: LockConfig.keyboardBackgroundOpacity
            activeBackgroundColor: LockConfig.keyboardBackgroundColor
            activeBackgroundOpacity: LockConfig.keyboardActiveBackgroundOpacity
            contentColor: LockConfig.keyboardContentColor
            activeContentColor: LockConfig.keyboardActiveContentColor
            active: menuArea.showKeyboard
            fontFamily: LockConfig.menuAreaButtonsFontFamily
            borderRadius: LockConfig.menuAreaButtonsBorderRadius
            borderSize: LockConfig.keyboardBorderSize
            enabled: menuArea.showKeyboard || menuArea.authState === "normal"
            activeFocusOnTab: true
            focus: false
            tooltipText: "Toggle virtual keyboard"
            onClicked: menuArea.toggleKeyboardRequested()
        }
    }

    Component {
        id: layoutMenuComponent

        LockIconButton {
            id: layoutButton
            property bool showLabel: LockConfig.layoutDisplayLayoutName

            height: LockConfig.menuAreaButtonsSize * LockConfig.generalScale * (Screen.width / 1920)
            icon: LockConfig.getIcon(LockConfig.layoutIcon)
            active: popup.visible
            borderRadius: LockConfig.menuAreaButtonsBorderRadius
            borderSize: LockConfig.layoutBorderSize
            iconSize: LockConfig.layoutIconSize
            fontSize: LockConfig.layoutFontSize
            backgroundColor: LockConfig.layoutBackgroundColor
            backgroundOpacity: LockConfig.layoutBackgroundOpacity
            activeBackgroundColor: LockConfig.layoutBackgroundColor
            activeBackgroundOpacity: LockConfig.layoutActiveBackgroundOpacity
            contentColor: LockConfig.layoutContentColor
            activeContentColor: LockConfig.layoutActiveContentColor
            fontFamily: LockConfig.menuAreaButtonsFontFamily
            activeFocusOnTab: true
            enabled: menuArea.authState === "normal" || popup.visible
            focus: false
            tooltipText: "Change keyboard layout"
            label: showLabel && LockLayouts.layouts.length > 0 && LockLayouts.currentLayout >= 0 && LockLayouts.currentLayout < LockLayouts.layouts.length ? LockLayouts.layouts[LockLayouts.currentLayout].toUpperCase() : ""
            onClicked: popup.open()

            Popup {
                id: popup
                parent: layoutButton
                padding: LockConfig.menuAreaPopupsPadding
                dim: true
                modal: true
                popupType: Popup.Item
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                focus: visible

                x: menuArea.calculatePopupPos(LockConfig.layoutPopupDirection, LockConfig.layoutPopupAlign, popup, layoutButton)[0]
                y: menuArea.calculatePopupPos(LockConfig.layoutPopupDirection, LockConfig.layoutPopupAlign, popup, layoutButton)[1]

                background: Rectangle {
                    color: LockConfig.menuAreaPopupsBackgroundColor
                    opacity: LockConfig.menuAreaPopupsBackgroundOpacity
                    radius: LockConfig.menuAreaButtonsBorderRadius * LockConfig.generalScale * (Screen.width / 1920)

                    Rectangle {
                        anchors.fill: parent
                        visible: LockConfig.menuAreaPopupsBorderSize > 0
                        radius: parent.radius
                        color: "transparent"
                        border {
                            color: LockConfig.menuAreaPopupsBorderColor
                            width: LockConfig.menuAreaPopupsBorderSize * LockConfig.generalScale * (Screen.width / 1920)
                        }
                    }
                }

                Overlay.modal: Rectangle {
                    color: "transparent"
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: function (event) {
                            popup.close()
                            event.accepted = true
                        }
                    }
                }

                LockLayoutSelector {
                    focus: popup.focus
                    onLayoutChanged: index => {
                        const code = LockLayouts.layouts.length > 0 && index >= 0 && index < LockLayouts.layouts.length ? LockLayouts.layouts[index] : ""
                        layoutButton.label = layoutButton.showLabel ? code.toUpperCase() : ""
                        VirtualKeyboardSettings.locale = LockLanguages.getKBCodeFor(code)
                    }
                    onCloseRequested: popup.close()
                }
            }
        }
    }

    Component {
        id: powerMenuComponent

        LockIconButton {
            id: powerButton
            height: LockConfig.menuAreaButtonsSize * LockConfig.generalScale * (Screen.width / 1920)
            width: LockConfig.menuAreaButtonsSize * LockConfig.generalScale * (Screen.width / 1920)
            icon: LockConfig.getIcon(LockConfig.powerIcon)
            iconSize: LockConfig.powerIconSize
            contentColor: LockConfig.powerContentColor
            activeContentColor: LockConfig.powerActiveContentColor
            fontFamily: LockConfig.menuAreaButtonsFontFamily
            active: popup.visible
            borderRadius: LockConfig.menuAreaButtonsBorderRadius
            borderSize: LockConfig.powerBorderSize
            backgroundColor: LockConfig.powerBackgroundColor
            backgroundOpacity: LockConfig.powerBackgroundOpacity
            activeBackgroundColor: LockConfig.powerBackgroundColor
            activeBackgroundOpacity: LockConfig.powerActiveBackgroundOpacity
            enabled: menuArea.authState === "normal" || popup.visible
            activeFocusOnTab: true
            focus: false
            tooltipText: "Power options"
            onClicked: popup.open()

            Popup {
                id: popup
                parent: powerButton
                padding: LockConfig.menuAreaPopupsPadding
                dim: true
                modal: true
                popupType: Popup.Item
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                focus: visible

                // Bound (not computed once in Component.onCompleted) because
                // popup.width/height aren't final until its content
                // (LockPowerMenu's ColumnLayout) finishes its first layout
                // pass — reading them too early collapsed height to 0 and
                // let the popup overlap the button instead of clearing it.
                x: menuArea.calculatePopupPos(LockConfig.powerPopupDirection, LockConfig.powerPopupAlign, popup, powerButton)[0]
                y: menuArea.calculatePopupPos(LockConfig.powerPopupDirection, LockConfig.powerPopupAlign, popup, powerButton)[1]

                background: Rectangle {
                    color: LockConfig.menuAreaPopupsBackgroundColor
                    opacity: LockConfig.menuAreaPopupsBackgroundOpacity
                    radius: LockConfig.menuAreaButtonsBorderRadius * LockConfig.generalScale * (Screen.width / 1920)

                    Rectangle {
                        anchors.fill: parent
                        visible: LockConfig.menuAreaPopupsBorderSize > 0
                        radius: parent.radius
                        color: "transparent"
                        border {
                            color: LockConfig.menuAreaPopupsBorderColor
                            width: LockConfig.menuAreaPopupsBorderSize * LockConfig.generalScale * (Screen.width / 1920)
                        }
                    }
                }

                Overlay.modal: Rectangle {
                    color: "transparent"
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: function (event) {
                            popup.close()
                            event.accepted = true
                        }
                    }
                }

                LockPowerMenu {
                    focus: popup.focus
                    onCloseRequested: popup.close()
                }
            }
        }
    }

    Row {
        id: topLeftButtons
        height: childrenRect.height
        width: childrenRect.width
        spacing: LockConfig.menuAreaButtonsSpacing
        anchors { top: parent.top; left: parent.left; topMargin: LockConfig.menuAreaButtonsMarginTop; leftMargin: LockConfig.menuAreaButtonsMarginLeft }
    }
    Row {
        id: topCenterButtons
        height: childrenRect.height
        width: childrenRect.width
        spacing: LockConfig.menuAreaButtonsSpacing
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: LockConfig.menuAreaButtonsMarginTop }
    }
    Row {
        id: topRightButtons
        height: childrenRect.height
        width: childrenRect.width
        spacing: LockConfig.menuAreaButtonsSpacing
        anchors { top: parent.top; right: parent.right; topMargin: LockConfig.menuAreaButtonsMarginTop; rightMargin: LockConfig.menuAreaButtonsMarginRight }
    }
    Column {
        id: centerLeftButtons
        height: childrenRect.height
        width: childrenRect.width
        spacing: LockConfig.menuAreaButtonsSpacing
        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: LockConfig.menuAreaButtonsMarginLeft }
    }
    Column {
        id: centerRightButtons
        height: childrenRect.height
        width: childrenRect.width
        spacing: LockConfig.menuAreaButtonsSpacing
        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: LockConfig.menuAreaButtonsMarginRight }
    }
    Row {
        id: bottomLeftButtons
        height: childrenRect.height
        width: childrenRect.width
        spacing: LockConfig.menuAreaButtonsSpacing
        anchors { bottom: parent.bottom; left: parent.left; bottomMargin: LockConfig.menuAreaButtonsMarginBottom; leftMargin: LockConfig.menuAreaButtonsMarginLeft }
    }
    Row {
        id: bottomCenterButtons
        height: childrenRect.height
        width: childrenRect.width
        spacing: LockConfig.menuAreaButtonsSpacing
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: LockConfig.menuAreaButtonsMarginBottom }
    }
    Row {
        id: bottomRightButtons
        height: childrenRect.height
        width: childrenRect.width
        spacing: LockConfig.menuAreaButtonsSpacing
        anchors { bottom: parent.bottom; right: parent.right; bottomMargin: LockConfig.menuAreaButtonsMarginBottom; rightMargin: LockConfig.menuAreaButtonsMarginRight }
    }

    property var createdObjects: []

    // LockConfig loads its .conf asynchronously — on a cold shell start this
    // could build the menu buttons before sortMenuButtons() sees the real
    // config, baking in the wrong layout for this surface's lifetime (same
    // race fixed in LockAuth.qml/LockIdle.qml). rebuildMenus() re-runs
    // whenever LockConfig.cfg actually updates, not just once.
    function rebuildMenus() {
        for (let i = 0; i < menuArea.createdObjects.length; i++) {
            if (menuArea.createdObjects[i]) menuArea.createdObjects[i].destroy()
        }
        menuArea.createdObjects = []

        const menus = LockConfig.sortMenuButtons()
        const positions = {
            "top-left": topLeftButtons, "top-center": topCenterButtons, "top-right": topRightButtons,
            "center-left": centerLeftButtons, "center-right": centerRightButtons,
            "bottom-left": bottomLeftButtons, "bottom-center": bottomCenterButtons, "bottom-right": bottomRightButtons
        }

        for (let i = 0; i < menus.length; i++) {
            const pos = positions[menus[i].position]
            if (!pos) continue

            let createdObject
            if (menus[i].name === "power") createdObject = powerMenuComponent.createObject(pos, {})
            else if (menus[i].name === "layout") createdObject = layoutMenuComponent.createObject(pos, {})
            else if (menus[i].name === "keyboard") createdObject = keyboardMenuComponent.createObject(pos, {})

            if (createdObject) menuArea.createdObjects.push(createdObject)
        }
    }

    Component.onCompleted: menuArea.rebuildMenus()

    Connections {
        target: LockConfig
        function onCfgChanged() { menuArea.rebuildMenus() }
    }

    Component.onDestruction: {
        for (let i = 0; i < menuArea.createdObjects.length; i++) {
            if (menuArea.createdObjects[i]) menuArea.createdObjects[i].destroy()
        }
        menuArea.createdObjects = []
    }

    function calculatePopupPos(direction, align, popup, button) {
        const popupMargin = LockConfig.menuAreaPopupsMargin
        let x = 0, y = 0

        if (direction === "up") {
            y = -popup.height - popupMargin
            x = align === "start" ? 0 : align === "end" ? -popup.width + button.width : (button.width - popup.width) / 2
        } else if (direction === "down") {
            y = button.height + popupMargin
            x = align === "start" ? 0 : align === "end" ? -popup.width + button.width : (button.width - popup.width) / 2
        } else if (direction === "left") {
            x = -popup.width - popupMargin
            y = align === "start" ? 0 : align === "end" ? -popup.height + button.height : (button.height - popup.height) / 2
        } else {
            x = button.width + popupMargin
            y = align === "start" ? 0 : align === "end" ? -popup.height + button.height : (button.height - popup.height) / 2
        }
        return [x, y]
    }
}
