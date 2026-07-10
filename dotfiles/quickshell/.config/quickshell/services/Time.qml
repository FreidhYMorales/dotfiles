pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property var now: clock.date

    readonly property string hours:    Qt.formatTime(now, "hh")
    readonly property string minutes:  Qt.formatTime(now, "mm")
    readonly property string seconds:  Qt.formatTime(now, "ss")
    readonly property string time24:   Qt.formatTime(now, "hh:mm")
    readonly property string timeFull: Qt.formatTime(now, "hh:mm:ss")
    readonly property string date:     Qt.formatDate(now, "ddd dd MMM")
    readonly property string hours12:  Qt.formatTime(now, "hh AP").split(" ")[0]
    readonly property string amPm:     Qt.formatTime(now, "AP")
    readonly property string fullDate: Qt.formatDate(now, "dddd, d MMMM yyyy")

    // Caelestia-compatible aliases used by the lock clock
    readonly property string hourStr:   Qt.formatTime(now, "hh")
    readonly property string minuteStr: Qt.formatTime(now, "mm")
    readonly property string amPmStr:   Qt.formatTime(now, "AP").toLowerCase()

    function format(fmt) {
        return Qt.formatDateTime(now, fmt)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
