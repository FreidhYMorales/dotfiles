pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import "../../services"

// Port of the SDDM "silent" theme's components/LayoutSelector.qml.
// keyboard.layouts/keyboard.currentLayout (SDDM-only) -> LockLayouts
// (services/LockLayouts.qml, Hyprland IPC). Hyprland only exposes short
// layout codes (no XKB "long name" like SDDM's native keyboard object), so
// the theme's two-line label+longName delegate is simplified to one line.
ColumnLayout {
    id: selector

    width: (LockConfig.layoutPopupWidth - LockConfig.menuAreaPopupsPadding * 2) * LockConfig.generalScale * (Screen.width / 1920)

    signal layoutChanged(int layoutIndex)
    signal closeRequested()

    property int currentLayoutIndex: LockLayouts.layouts.length > 0 ? LockLayouts.currentLayout : 0

    function updateLayout() {
        if (LockLayouts.layouts.length > 0 && selector.currentLayoutIndex >= 0 && selector.currentLayoutIndex < LockLayouts.layouts.length)
            LockLayouts.switchTo(selector.currentLayoutIndex)
        selector.layoutChanged(selector.currentLayoutIndex)
    }

    Text {
        id: noLayoutMessage
        Layout.preferredWidth: parent.width - 5
        text: "No keyboard layout could be found."
        visible: LockLayouts.layouts.length === 0
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        color: LockConfig.menuAreaPopupsContentColor
        font.pixelSize: LockConfig.menuAreaPopupsFontSize * LockConfig.generalScale * (Screen.width / 1920)
        font.family: LockConfig.menuAreaPopupsFontFamily
        padding: 10
    }

    ListView {
        id: layoutList
        visible: !noLayoutMessage.visible
        Layout.preferredWidth: parent.width
        Layout.preferredHeight: Math.min(LockLayouts.layouts.length * ((LockConfig.menuAreaPopupsItemHeight * LockConfig.generalScale * (Screen.width / 1920)) + 5 + spacing) - spacing, LockConfig.menuAreaPopupsMaxHeight * LockConfig.generalScale * (Screen.width / 1920))
        orientation: ListView.Vertical
        interactive: true
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: LockConfig.menuAreaPopupsSpacing
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 0

        contentHeight: LockLayouts.layouts.length * ((LockConfig.menuAreaPopupsItemHeight * LockConfig.generalScale * (Screen.width / 1920)) + 5 + spacing) - spacing

        ScrollBar.vertical: ScrollBar {
            id: scrollbar
            policy: LockConfig.menuAreaPopupsDisplayScrollbar && layoutList.contentHeight > layoutList.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth: 5 * LockConfig.generalScale * (Screen.width / 1920)
                radius: 5 * LockConfig.generalScale * (Screen.width / 1920)
                color: LockConfig.menuAreaPopupsContentColor
                opacity: LockConfig.menuAreaPopupsActiveOptionBackgroundOpacity
            }
        }

        model: LockLayouts.layouts

        delegate: Rectangle {
            id: delegateRoot
            required property string modelData
            required property int index

            width: scrollbar.visible ? selector.width - LockConfig.menuAreaPopupsPadding - scrollbar.width : selector.width
            height: childrenRect.height
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: LockConfig.menuAreaPopupsActiveOptionBackgroundColor
                opacity: delegateRoot.index === selector.currentLayoutIndex ? LockConfig.menuAreaPopupsActiveOptionBackgroundOpacity : (mouseArea.containsMouse ? LockConfig.menuAreaPopupsActiveOptionBackgroundOpacity : 0.0)
                radius: 5
            }

            RowLayout {
                width: parent.width
                height: (LockConfig.menuAreaPopupsItemHeight * LockConfig.generalScale * (Screen.width / 1920)) + 5
                spacing: 0

                Rectangle {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: Layout.preferredHeight
                    color: "transparent"

                    Image {
                        id: flagIcon
                        anchors.centerIn: parent
                        source: delegateRoot.modelData.length > 0 ? `file:///usr/share/sddm/flags/${delegateRoot.modelData}.png` : `file://${LockConfig.getIcon("language")}`
                        width: LockConfig.menuAreaPopupsIconSize * LockConfig.generalScale * (Screen.width / 1920)
                        height: width
                        sourceSize: Qt.size(width, height)
                        fillMode: Image.PreserveAspectFit

                        onStatusChanged: {
                            if (status === Image.Error) flagIcon.source = `file://${LockConfig.getIcon("language")}`
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true
                    text: LockLanguages.getLabelFor(delegateRoot.modelData) || delegateRoot.modelData.toUpperCase()
                    color: delegateRoot.index === selector.currentLayoutIndex || mouseArea.containsMouse ? LockConfig.menuAreaPopupsActiveContentColor : LockConfig.menuAreaPopupsContentColor
                    font.pixelSize: LockConfig.menuAreaPopupsFontSize * LockConfig.generalScale * (Screen.width / 1920)
                    font.family: LockConfig.menuAreaPopupsFontFamily
                    elide: Text.ElideRight
                    rightPadding: 10
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                enabled: delegateRoot.index !== selector.currentLayoutIndex
                hoverEnabled: delegateRoot.index !== selector.currentLayoutIndex
                z: 2
                cursorShape: hoverEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    selector.currentLayoutIndex = delegateRoot.index
                    selector.updateLayout()
                }
            }
        }
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Down) {
            if (LockLayouts.layouts.length > 0) {
                selector.currentLayoutIndex = (selector.currentLayoutIndex + LockLayouts.layouts.length + 1) % LockLayouts.layouts.length
                selector.updateLayout()
            }
        } else if (event.key === Qt.Key_Up) {
            if (LockLayouts.layouts.length > 0) {
                selector.currentLayoutIndex = (selector.currentLayoutIndex + LockLayouts.layouts.length - 1) % LockLayouts.layouts.length
                selector.updateLayout()
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            selector.closeRequested()
        }
    }
}
