pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Window
import "../../services"

// Port of the SDDM "silent" theme's components/Spinner.qml, simplified to
// always lay out vertically (icon above text) — this lockscreen stacks the
// auth area as a single column regardless of LoginScreen.LoginArea/position.
Item {
    id: spinnerContainer

    width: Math.max(spinner.width, spinnerText.width) * LockConfig.generalScale * (Screen.width / 1920)
    height: (spinner.height + LockConfig.spinnerSpacing + spinnerText.height) * LockConfig.generalScale * (Screen.width / 1920)

    Image {
        id: spinner
        source: LockConfig.getIcon(LockConfig.spinnerIcon)
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: LockConfig.spinnerIconSize * LockConfig.generalScale * (Screen.width / 1920)
        height: width
        sourceSize.width: width
        sourceSize.height: height
        visible: false
    }

    MultiEffect {
        id: spinnerEffect
        source: spinner
        anchors.fill: spinner
        colorization: 1
        colorizationColor: LockConfig.spinnerColor
        antialiasing: true
    }

    RotationAnimation {
        target: spinnerEffect
        running: spinnerContainer.visible && LockConfig.enableAnimations
        from: 0
        to: 360
        loops: Animation.Infinite
        duration: 1200
    }

    Text {
        id: spinnerText
        visible: LockConfig.spinnerDisplayText
        text: LockConfig.spinnerText
        color: LockConfig.spinnerColor
        font.pixelSize: LockConfig.spinnerFontSize * LockConfig.generalScale * (Screen.width / 1920)
        font.weight: LockConfig.spinnerFontWeight
        font.family: LockConfig.spinnerFontFamily
        anchors.top: spinner.bottom
        anchors.topMargin: LockConfig.spinnerSpacing
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
