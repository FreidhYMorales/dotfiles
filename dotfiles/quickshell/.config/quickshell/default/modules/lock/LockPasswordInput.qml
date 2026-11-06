pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window
import "../../services"

// Port of the SDDM "silent" theme's components/Input.qml.
Item {
    id: input

    signal accepted()

    property string placeholder: ""
    property alias input: textField
    property bool isPassword: false
    property bool splitBorderRadius: false
    property alias text: textField.text
    property string icon: ""
    property bool enabled: true

    width: LockConfig.passwordInputWidth * LockConfig.generalScale * (Screen.width / 1920)
    height: LockConfig.passwordInputHeight * LockConfig.generalScale * (Screen.width / 1920)

    TextField {
        id: textField
        anchors.fill: parent
        color: LockConfig.passwordInputContentColor
        enabled: input.enabled
        echoMode: input.isPassword ? TextInput.Password : TextInput.Normal
        passwordCharacter: LockConfig.passwordInputMaskedCharacter
        activeFocusOnTab: true
        selectByMouse: true
        verticalAlignment: TextField.AlignVCenter
        font.family: LockConfig.passwordInputFontFamily
        font.pixelSize: Math.max(8, LockConfig.passwordInputFontSize * LockConfig.generalScale * (Screen.width / 1920))
        leftPadding: placeholderLabel.x
        rightPadding: 10
        onAccepted: input.accepted()

        background: Rectangle {
            anchors.fill: parent
            color: LockConfig.passwordInputBackgroundColor
            opacity: LockConfig.passwordInputBackgroundOpacity
            topLeftRadius: LockConfig.passwordInputBorderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
            bottomLeftRadius: LockConfig.passwordInputBorderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
            topRightRadius: input.splitBorderRadius ? LockConfig.passwordInputBorderRadiusRight * LockConfig.generalScale * (Screen.width / 1920) : LockConfig.passwordInputBorderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
            bottomRightRadius: input.splitBorderRadius ? LockConfig.passwordInputBorderRadiusRight * LockConfig.generalScale * (Screen.width / 1920) : LockConfig.passwordInputBorderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
        }

        Rectangle {
            anchors.fill: parent
            border.width: LockConfig.passwordInputBorderSize * LockConfig.generalScale * (Screen.width / 1920)
            border.color: LockConfig.passwordInputBorderColor
            color: "transparent"
            topLeftRadius: LockConfig.passwordInputBorderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
            bottomLeftRadius: LockConfig.passwordInputBorderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
            topRightRadius: input.splitBorderRadius ? LockConfig.passwordInputBorderRadiusRight * LockConfig.generalScale * (Screen.width / 1920) : LockConfig.passwordInputBorderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
            bottomRightRadius: input.splitBorderRadius ? LockConfig.passwordInputBorderRadiusRight * LockConfig.generalScale * (Screen.width / 1920) : LockConfig.passwordInputBorderRadiusLeft * LockConfig.generalScale * (Screen.width / 1920)
        }

        Row {
            anchors.fill: parent
            spacing: 0
            leftPadding: LockConfig.passwordInputDisplayIcon ? 2 : 10

            Rectangle {
                id: iconContainer
                color: "transparent"
                visible: LockConfig.passwordInputDisplayIcon
                height: parent.height
                width: height

                Image {
                    id: icon
                    source: input.icon
                    anchors.centerIn: parent
                    width: Math.max(1, LockConfig.passwordInputIconSize * LockConfig.generalScale * (Screen.width / 1920))
                    height: width
                    sourceSize: Qt.size(width, height)
                    fillMode: Image.PreserveAspectFit
                    opacity: input.enabled ? 1.0 : 0.3

                    MultiEffect {
                        source: icon
                        anchors.fill: icon
                        colorization: 1
                        colorizationColor: textField.color
                    }
                }
            }

            Text {
                id: placeholderLabel
                anchors.verticalCenter: parent.verticalCenter
                padding: 0
                visible: textField.text.length === 0 && (!textField.preeditText || textField.preeditText.length === 0)
                text: input.placeholder
                color: textField.color
                font.pixelSize: Math.max(8, textField.font.pixelSize || 12)
                font.family: textField.font.family || "sans-serif"
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: textField.verticalAlignment
                font.italic: true
            }
        }
    }
}
