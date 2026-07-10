pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Notifications

// Notification data object — one per notification.
// Compatible with Caelestia's NotifData API used in NotifGroup.qml.
QtObject {
    id: notif

    property bool   popup:      false
    property bool   closed:     false
    property var    locks:      []

    property date   time:       new Date()
    property string timeStr:    qsTr("now")

    property string notificationId: ""
    property string summary:    ""
    property string body:       ""
    property string appIcon:    ""
    property string appName:    ""
    property string image:      ""
    property real   expireTimeout: 5000
    property int    urgency:    NotificationUrgency.Normal
    property bool   resident:   false
    property bool   hasActionIcons: false
    property list<var> actions: []

    readonly property Timer timeStrTimer: Timer {
        running: !notif.closed
        repeat:  true
        interval: 5000
        onTriggered: notif.updateTimeStr()
    }

    function updateTimeStr() {
        const diff = Date.now() - time.getTime()
        const m    = Math.floor(diff / 60000)
        if (m < 1) {
            timeStr = qsTr("now")
        } else {
            const h = Math.floor(m / 60)
            const d = Math.floor(h / 24)
            if (d > 0) timeStr = `${d}d`
            else if (h > 0) timeStr = `${h}h`
            else timeStr = `${m}m`
        }
    }

    function lock(item) {
        locks = [...locks, item]
    }

    function unlock(item) {
        locks = locks.filter(l => l !== item)
        if (closed) close()
    }

    function close() {
        closed = true
        if (locks.length === 0) {
            destroy()
        }
    }
}
