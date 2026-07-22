import QtQuick
import "../../services"
import "../../components"

Item {
    id: root

    property var _now:   new Date()
    property int _year:  _now.getFullYear()
    property int _month: _now.getMonth()

    // Refresh _now when Time ticks to a new date
    Connections {
        target: Time
        function onNowChanged() {
            const t = Time.now
            const n = root._now
            if (t.getFullYear() !== n.getFullYear() ||
                t.getMonth()    !== n.getMonth()    ||
                t.getDate()     !== n.getDate()) {
                root._now = t
            }
        }
    }

    function buildDays(year, month) {
        const days = []
        const first       = new Date(year, month, 1).getDay()   // 0=Sun
        const offset      = (first + 6) % 7                     // Mon-based offset
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const daysInPrev  = new Date(year, month, 0).getDate()

        for (let i = offset - 1; i >= 0; i--)
            days.push({ day: daysInPrev - i, thisMonth: false })

        for (let d = 1; d <= daysInMonth; d++)
            days.push({ day: d, thisMonth: true })

        while (days.length % 7 !== 0)
            days.push({ day: days.length - daysInMonth - offset + 1, thisMonth: false })

        return days
    }

    function monthName(m) {
        return ["January","February","March","April","May","June",
                "July","August","September","October","November","December"][m]
    }

    Column {
        anchors {
            fill:        parent
            leftMargin:  12
            rightMargin: 12
            topMargin:   8
        }
        spacing: 6

        // Header
        Item {
            width:  parent.width
            height: 36

            // Prev button
            Item {
                id:     prevBtn
                width:  28
                height: 28
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius:       7
                    color:        prevHov.hovered
                                      ? Qt.alpha(Colours.m3onSurface, 0.08)
                                      : "transparent"
                    Behavior on color { CAnim {} }
                }

                Text {
                    anchors.centerIn: parent
                    text:           "󰅁"
                    font.family:    Style.fontFamily
                    font.pixelSize: 16
                    color:          Colours.m3onSurface
                    Behavior on color { CAnim {} }
                }

                HoverHandler { id: prevHov }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        root._month--
                        if (root._month < 0) {
                            root._month = 11
                            root._year--
                        }
                    }
                }
            }

            // Month + year label
            Text {
                anchors.centerIn: parent
                text:           root.monthName(root._month) + " " + root._year
                font.family:    Style.fontFamily
                font.pixelSize: 13
                font.weight:    Font.Medium
                color:          Colours.m3onSurface
                Behavior on color { CAnim {} }
            }

            // Next button
            Item {
                id:     nextBtn
                width:  28
                height: 28
                anchors {
                    right:         parent.right
                    verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    anchors.fill: parent
                    radius:       7
                    color:        nextHov.hovered
                                      ? Qt.alpha(Colours.m3onSurface, 0.08)
                                      : "transparent"
                    Behavior on color { CAnim {} }
                }

                Text {
                    anchors.centerIn: parent
                    text:           "󰅂"
                    font.family:    Style.fontFamily
                    font.pixelSize: 16
                    color:          Colours.m3onSurface
                    Behavior on color { CAnim {} }
                }

                HoverHandler { id: nextHov }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        root._month++
                        if (root._month > 11) {
                            root._month = 0
                            root._year++
                        }
                    }
                }
            }
        }

        // Weekday labels
        Row {
            width:   parent.width
            spacing: 0

            Repeater {
                model: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
                delegate: Text {
                    required property string modelData
                    width:          parent.width / 7
                    text:           modelData
                    horizontalAlignment: Text.AlignHCenter
                    font.family:    Style.fontFamily
                    font.pixelSize: 10
                    color:          Colours.m3onSurfaceVariant
                    Behavior on color { CAnim {} }
                }
            }
        }

        // Day grid
        Grid {
            id:      dayGrid
            width:   parent.width
            columns: 7

            Repeater {
                model: root.buildDays(root._year, root._month)

                delegate: Item {
                    required property var modelData
                    width:  dayGrid.width / 7
                    height: 32

                    readonly property bool isToday: modelData.thisMonth &&
                        modelData.day === root._now.getDate() &&
                        root._month   === root._now.getMonth() &&
                        root._year    === root._now.getFullYear()

                    Rectangle {
                        anchors.centerIn: parent
                        width:   24
                        height:  24
                        radius:  12
                        visible: isToday
                        color:   Colours.m3primary
                        Behavior on color { CAnim {} }
                    }

                    Text {
                        anchors.centerIn: parent
                        text:             modelData.day
                        font.family:      Style.fontFamily
                        font.pixelSize:   12
                        horizontalAlignment: Text.AlignHCenter
                        color: isToday
                                   ? Colours.m3onPrimary
                                   : modelData.thisMonth
                                       ? Colours.m3onSurface
                                       : Qt.alpha(Colours.m3onSurface, 0.35)
                        Behavior on color { CAnim {} }
                    }
                }
            }
        }
    }
}
