pragma ComponentBehavior: Bound

import QtQuick
import "../../services"
import "../../components"

// Intro glyph (line → brackets) for the launcher's open/close animation.
// Two spines start coincident at separation 0 (reads as a single line — the
// "point splitting in two" from the brief, without a dedicated stage), then
// separate while growing corner ticks to form "[" / "]" around the Arch
// icon. Sits outside panelRect in LauncherContent so its own opacity isn't
// multiplied by panelRect's (which stays 0 through this whole phase).
//
// spineH/separation/capReveal are driven externally by LauncherContent's
// openAnim/closeAnim (NumberAnimation { target: introGroup; property: ... }),
// so they stay plain writable properties rather than internal state.
Item {
    id: introGroup

    required property string stage
    required property real   searchH

    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    // Same footprint panelRect itself reserves for closed/line/brackets/
    // closing — the glyph fills the exact box the panel is about to grow
    // out of, instead of an arbitrary smaller size.
    width:  60
    height: introGroup.searchH + 8
    opacity: (introGroup.stage === "line" || introGroup.stage === "brackets") ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 140 } }

    // Spine height matches searchH exactly — the bar it hands off to is
    // that tall, so the brackets read as the same size as what they're
    // about to become instead of jumping in height.
    readonly property real spineHTarget:     introGroup.searchH
    readonly property real separationTarget: 30
    // Matches panelRect's own border.width (2) in the bar/open stages.
    readonly property real spineW: 2
    readonly property real capW:   7

    property real spineH:     0
    property real separation: 0
    property real capReveal:  0

    readonly property real _cx:     width / 2
    readonly property real _spineY: height / 2 - spineH / 2

    // Left / right spines
    Rectangle {
        x: introGroup._cx - introGroup.separation / 2 - introGroup.spineW / 2
        y: introGroup._spineY
        width:  introGroup.spineW
        height: introGroup.spineH
        color:  Colours.m3primary
        Behavior on color { CAnim {} }
    }
    Rectangle {
        x: introGroup._cx + introGroup.separation / 2 - introGroup.spineW / 2
        y: introGroup._spineY
        width:  introGroup.spineW
        height: introGroup.spineH
        color:  Colours.m3primary
        Behavior on color { CAnim {} }
    }

    // "[" corner ticks — extend right (inward) from the left spine
    Rectangle {
        x: introGroup._cx - introGroup.separation / 2 - introGroup.spineW / 2
        y: introGroup._spineY
        width:  introGroup.spineW + introGroup.capReveal * introGroup.capW
        height: introGroup.spineW
        color:  Colours.m3primary
        Behavior on color { CAnim {} }
    }
    Rectangle {
        x: introGroup._cx - introGroup.separation / 2 - introGroup.spineW / 2
        y: introGroup._spineY + introGroup.spineH - introGroup.spineW
        width:  introGroup.spineW + introGroup.capReveal * introGroup.capW
        height: introGroup.spineW
        color:  Colours.m3primary
        Behavior on color { CAnim {} }
    }

    // "]" corner ticks — extend left (inward) from the right spine
    Rectangle {
        x: introGroup._cx + introGroup.separation / 2 - introGroup.spineW / 2
           - introGroup.capReveal * introGroup.capW
        y: introGroup._spineY
        width:  introGroup.spineW + introGroup.capReveal * introGroup.capW
        height: introGroup.spineW
        color:  Colours.m3primary
        Behavior on color { CAnim {} }
    }
    Rectangle {
        x: introGroup._cx + introGroup.separation / 2 - introGroup.spineW / 2
           - introGroup.capReveal * introGroup.capW
        y: introGroup._spineY + introGroup.spineH - introGroup.spineW
        width:  introGroup.spineW + introGroup.capReveal * introGroup.capW
        height: introGroup.spineW
        color:  Colours.m3primary
        Behavior on color { CAnim {} }
    }

    // Arch icon — tied directly to capReveal (not the "brackets" stage
    // name) so it fades in/out in lockstep with the ticks. The stage stays
    // "brackets" during both formation AND collapse, so a stage-based
    // opacity toggle left the icon stuck fully visible while the brackets
    // were already un-forming on close.
    Text {
        anchors.centerIn: parent
        text:           "󰣇"
        color:          Colours.m3primary
        font.family:    Style.fontFamily
        font.pixelSize: 26
        opacity:        introGroup.capReveal
        Behavior on color { CAnim {} }
    }
}
