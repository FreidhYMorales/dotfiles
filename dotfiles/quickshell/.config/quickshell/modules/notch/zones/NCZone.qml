pragma ComponentBehavior: Bound

import QtQuick
import "../../../services"
import "../../../components"
import "../../../components/controls"
import "../../bar"

// N-C zone — persistently-visible top-center notch content. Unlike TL
// (NotchDropdown, vertical reveal, hidden at idle), N-C is the ONE zone
// that never hides: it stays put and morphs its CONTENT horizontally
// between states (idle clock+glance meters <-> equalizer while music plays
// <-> hover-expand to media/calendar/volume/etc., that last part Phase 3+
// scope). Wrapped in the ORIGINAL NotchZone (horizontal pill-expand base
// from Phase 0), not NotchDropdown/CornerPill — those are TL's vertical-
// reveal/corner-silhouette machinery and don't apply to a true center zone.
//
// Phase 2 scope: idle state (clock + tiny CPU/RAM glance meters) and the
// equalizer swap while Mpris.playing. Hover-expand-to-media content is NOT
// built yet (Phase 3) — hoverToExpand is left at NotchZone's default (true)
// as a harmless placeholder since there is no conditional extra content to
// expand into this phase; idleWidth is bound to the idle row's own natural
// width so hovering doesn't animate to/from an arbitrary different size.
Item {
    id: root

    property var colors: Colours.palette

    implicitWidth:  zone.implicitWidth
    implicitHeight: zone.implicitHeight

    // Chrome as a sibling bound to `zone`'s live (animated) size — same
    // "chrome outside NotchZone's content" convention TLZone uses around
    // NotchDropdown, avoiding a childrenRect sizing loop. Solid fill, no
    // colored border. Top corners SQUARE (N-C's PanelWindow is flush
    // against the real top screen edge — same "square where touching a
    // screen edge" rule already applied to TL, just for one edge instead
    // of two), bottom corners rounded (free, not touching anything) — Qt
    // 6.7+ native per-corner Rectangle radius, no Shape/PathArc needed.
    Rectangle {
        anchors.fill:      zone
        topLeftRadius:     0
        topRightRadius:    0
        bottomLeftRadius:  zone.height / 2
        bottomRightRadius: zone.height / 2
        color:             root.colors.m3surfaceContainerHigh
        Behavior on color { CAnim {} }
    }

    NotchZone {
        id: zone
        idleWidth: idleRow.implicitWidth

        Row {
            id: idleRow
            spacing:      8
            leftPadding:   12
            rightPadding:  12
            // topPadding/bottomPadding: 6+6=12, combined with the 30px
            // content row = 42px total — matches TL's own content height
            // exactly (26px icon + 8+8 padding = 42px) on request.
            topPadding:    6
            bottomPadding: 6

            // Bigger than the bar's default scale (12px font / 26px tall),
            // but dialed back from an earlier over-scaled pass (20px/38px)
            // that only became visible once components/NotchZone.qml's
            // clip-height bug was fixed — moderate bump instead, close to
            // TL's own 26px workspace-circle scale. ClockWidget's size is
            // overridable per-instance so this doesn't also resize the
            // (currently hidden) bar's own clock.
            ClockWidget {
                colors:        root.colors
                fontPixelSize: 15
                widgetHeight:  30
            }

            // Tiny CPU/RAM glance meters — two side-by-side ArcMeter rings
            // (circular progress + centered icon), replacing the previous
            // stacked SegmentedMeter bars. Side-by-side reads more legible
            // at this compact scale than stacking two rings vertically in
            // an 26px-tall row. Icons reused from
            // modules/dashboard/PerformanceSection.qml's BlockMetric rows
            // (same glyphs, same m3primary/m3secondary accent split) for
            // project-wide consistency. Swapped for the equalizer glyph
            // below while music is playing.
            Row {
                id: metrics
                spacing: 4
                visible: !Mpris.playing
                anchors.verticalCenter: parent.verticalCenter

                ArcMeter {
                    width:         30
                    height:        30
                    ringWidth:     3
                    iconPixelSize: 13
                    value:         SysInfo.cpu
                    icon:          "󰻠"
                    colors:        root.colors
                    ringColor:     root.colors.m3primary
                }

                ArcMeter {
                    width:         30
                    height:        30
                    ringWidth:     3
                    iconPixelSize: 13
                    value:         SysInfo.ram
                    icon:          "󰑭"
                    colors:        root.colors
                    ringColor:     root.colors.m3secondary
                }
            }

            // Small animated equalizer glyph — 4 bars, each independently
            // re-targeting a random height on its own short-interval timer
            // while Mpris.playing. No real audio-spectrum data is available
            // or in scope here — this is a decorative "something is
            // playing" glance, same spirit/size envelope as the CPU/RAM
            // rings it replaces.
            Item {
                id:      eqHolder
                width:   22
                height:  30
                visible: Mpris.playing

                Row {
                    id: eqRow
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: 4

                        delegate: Item {
                            id: eqBar
                            required property int index
                            width:  3
                            height: 18

                            Rectangle {
                                id: bar
                                anchors.bottom: parent.bottom
                                width:  parent.width
                                radius: 1.5
                                color:  root.colors.m3primary
                                height: 5
                                Behavior on height {
                                    NumberAnimation { duration: 220; easing.type: Easing.InOutSine }
                                }
                            }

                            Timer {
                                interval:         260 + eqBar.index * 37
                                running:          eqHolder.visible
                                repeat:            true
                                triggeredOnStart: true
                                onTriggered: bar.height = 5 + Math.random() * 12
                            }
                        }
                    }
                }
            }
        }
    }
}
