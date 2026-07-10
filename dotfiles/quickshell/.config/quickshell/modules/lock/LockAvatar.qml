pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Window
import "../../services"
import "../../utils"

// Port of the SDDM "silent" theme's components/Avatar.qml, simplified for a
// single-user lockscreen (always "active" — no UserSelector to switch
// between users, so no click/clickedOutside selection signals).
Rectangle {
    id: avatar

    property string shape: LockConfig.avatarShape
    property string source: `file://${Paths.home}/.face`
    property int squareRadius: (shape === "circle") ? avatar.width : (LockConfig.avatarBorderRadius === 0 ? 1 : LockConfig.avatarBorderRadius * LockConfig.generalScale * (Screen.width / 1920))
    property string tooltipText: ""

    width: LockConfig.avatarActiveSize * LockConfig.generalScale * (Screen.width / 1920)
    height: width
    radius: squareRadius
    color: "transparent"
    antialiasing: true

    Rectangle {
        anchors.fill: parent
        radius: avatar.squareRadius
        color: LockConfig.passwordInputBackgroundColor
        opacity: LockConfig.passwordInputBackgroundOpacity
    }

    Image {
        id: faceImage
        source: avatar.source
        anchors.fill: parent
        mipmap: true
        antialiasing: true
        visible: false
        smooth: true
        fillMode: Image.PreserveAspectCrop
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter

        onStatusChanged: {
            if (status === Image.Error)
                source = `file://${LockConfig.getIcon("user-default")}`
        }

        Rectangle {
            anchors.fill: parent
            radius: avatar.squareRadius
            color: "transparent"
            border.width: LockConfig.avatarActiveBorderSize * LockConfig.generalScale * (Screen.width / 1920)
            border.color: LockConfig.avatarActiveBorderColor
            antialiasing: true
        }
    }

    MultiEffect {
        id: faceEffects
        anchors.fill: faceImage
        source: faceImage
        antialiasing: true
        maskEnabled: true
        maskSource: faceImageMask
        maskSpreadAtMin: 1.0
        maskThresholdMax: 1.0
        maskThresholdMin: 0.5
    }

    Item {
        id: faceImageMask
        height: faceImageMask.width
        layer.enabled: true
        layer.smooth: true
        visible: false
        width: faceImage.width

        Rectangle {
            height: parent.width
            radius: avatar.squareRadius
            width: faceImage.width
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor

        ToolTip {
            parent: mouseArea
            enabled: LockConfig.tooltipsEnable && !LockConfig.tooltipsDisableUser
            visible: enabled && mouseArea.containsMouse && avatar.tooltipText !== ""
            delay: 300
            contentItem: Text {
                font.family: LockConfig.tooltipsFontFamily
                font.pixelSize: LockConfig.tooltipsFontSize * LockConfig.generalScale * (Screen.width / 1920)
                text: avatar.tooltipText
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
}
