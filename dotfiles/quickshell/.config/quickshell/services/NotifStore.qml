pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property ListModel notifications: ListModel {}
    property int unread: 0

    function receive(notif) {
        notifications.insert(0, {
            "app":     notif.appName  ?? "",
            "summary": notif.summary  ?? "",
            "body":    notif.body     ?? "",
            "icon":    notif.appIcon  ?? "",
            "urgency": notif.urgency  ?? 1
        })
        unread++
    }

    function clear() {
        notifications.clear()
        unread = 0
    }

    function dismiss(index) {
        if (index >= 0 && index < notifications.count) {
            notifications.remove(index, 1)
            if (unread > 0) unread--
        }
    }
}
