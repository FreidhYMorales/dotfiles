pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Window
import "../../services"

// Port of the SDDM "silent" theme's components/IconButton.qml — no SDDM
// dependency, only Config -> LockConfig renamed. Used by the login button
// here and by the power/layout/keyboard menu in later phases.
Item {
    id: iconButton

    signal clicked()

    property bool active: false
    readonly property bool isActive: active || focus || mouseArea.pressed || mouseArea.containsMouse
    property string icon: ""
    property int iconSize: 16
    property color contentColor: "#FFFFFF"
    property color activeContentColor: "#FFFFFF"
    property string label: ""
    property bool showLabel: true
    property string fontFamily: "RedHatDisplay"
    property int fontWeight: 400
    property int fontSize: 12
    property color backgroundColor: "#FFFFFF"
    property real backgroundOpacity: 0.0
    property color activeBackgroundColor: "#FFFFFF"
    property real activeBackgroundOpacity: 0.15
    property string tooltipText: ""
    property int borderRadius: 10
    property int borderRadiusLeft: borderRadius
    property int borderRadiusRight: borderRadius
    property int borderSize: 0
    property color borderColor: isActive ? iconButton.activeContentColor : iconButton.contentColor
    property int preferredWidth: -1

    width: preferredWidth !== -1 ? (preferredWidth * LockConfig.generalScale * (Screen.width / 1920)) : buttonContentRow.width
    height: iconSize * 2 * LockConfig.generalScale * (Screen.width / 1920)

    Rectangle {
        id: buttonBackground
        anchors.fill: parent
        color: iconButton.isActive ? iconButton.activeBackgroundColor : iconButton.backgroundColor
        opacity: iconButton.isActive ? iconButton.activeBackgroundOpacity : iconButton.backgroundOpacity
        topLeftRadius: iconButton.borderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
        topRightRadius: iconButton.borderRadiusRight * LockConfig.generalScale * (Screen.width / 1920)
        bottomLeftRadius: iconButton.borderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
        bottomRightRadius: iconButton.borderRadiusRight * LockConfig.generalScale * (Screen.width / 1920)
    }

    Rectangle {
        id: buttonBorder
        color: "transparent"
        topLeftRadius: iconButton.borderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
        topRightRadius: iconButton.borderRadiusRight * LockConfig.generalScale * (Screen.width / 1920)
        bottomLeftRadius: iconButton.borderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
        bottomRightRadius: iconButton.borderRadiusRight * LockConfig.generalScale * (Screen.width / 1920)
        anchors.fill: parent
        visible: iconButton.borderSize > 0 || iconButton.focus
        border {
            color: iconButton.borderColor
            width: iconButton.focus ? (iconButton.borderSize * LockConfig.generalScale * (Screen.width / 1920)) || 2 : (iconButton.borderSize > 0 ? (iconButton.borderSize * LockConfig.generalScale * (Screen.width / 1920)) : 0)
        }
    }

    RowLayout {
        id: buttonContentRow
        height: parent.height
        spacing: 0

        Rectangle {
            id: iconContainer
            color: "transparent"
            Layout.preferredWidth: parent.height
            Layout.preferredHeight: parent.height

            Image {
                id: buttonIcon
                source: iconButton.icon
                anchors.centerIn: parent
                width: iconButton.iconSize * LockConfig.generalScale * (Screen.width / 1920)
                height: width
                sourceSize: Qt.size(width, height)
                fillMode: Image.PreserveAspectFit
                visible: false
            }

            MultiEffect {
                id: iconEffect
                source: buttonIcon
                anchors.fill: buttonIcon
                colorization: 1
                colorizationColor: iconButton.isActive ? iconButton.activeContentColor : iconButton.contentColor
                antialiasing: true
                opacity: iconButton.enabled ? 1.0 : 0.5
            }
        }

        Text {
            id: buttonLabel
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: iconButton.label
            visible: iconButton.showLabel && text !== ""
            font.family: iconButton.fontFamily
            font.pixelSize: iconButton.fontSize * LockConfig.generalScale * (Screen.width / 1920)
            font.weight: iconButton.fontWeight
            rightPadding: 10
            color: iconButton.isActive ? iconButton.activeContentColor : iconButton.contentColor
            opacity: iconButton.enabled ? 1.0 : 0.5

            Component.onCompleted: {
                if (iconButton.preferredWidth !== -1)
                    buttonLabel.Layout.preferredWidth = iconButton.width - iconContainer.width
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: parent.enabled
        onClicked: iconButton.clicked()
        cursorShape: Qt.PointingHandCursor

        ToolTip {
            parent: mouseArea
            enabled: LockConfig.tooltipsEnable
            property bool shouldShow: (enabled && mouseArea.containsMouse && iconButton.tooltipText !== "") || (enabled && iconButton.focus && iconButton.tooltipText !== "")
            visible: shouldShow
            delay: 300

            contentItem: Text {
                font.family: LockConfig.tooltipsFontFamily
                font.pixelSize: LockConfig.tooltipsFontSize * LockConfig.generalScale * (Screen.width / 1920)
                text: iconButton.tooltipText
                color: LockConfig.tooltipsContentColor
            }

            background: Rectangle {
                color: LockConfig.tooltipsBackgroundColor
                opacity: LockConfig.tooltipsBackgroundOpacity
                border.width: 0
                radius: LockConfig.tooltipsBorderRadius * LockConfig.generalScale * (Screen.width / 1920)
            }
        }
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
            iconButton.clicked()
    }
}
