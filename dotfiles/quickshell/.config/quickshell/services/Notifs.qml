pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification service — wraps Quickshell's NotificationServer.
// Exposes Caelestia-compatible API: list, notClosed.
// Note: NotificationServer must be instantiated in ShellRoot (shell.qml).
// This service receives notifications via the receive() function called from shell.qml.
Singleton {
    id: root

    property list<var> list:      []
    readonly property list<var> notClosed: list.filter(n => !n.closed)

    // Called from shell.qml's NotificationServer.onNotification handler
    function receive(notification) {
        const comp = notifComp.createObject(root, {
            popup:          true,
            notificationId: notification.id,
            summary:        notification.summary,
            body:           notification.body,
            appIcon:        notification.appIcon,
            appName:        notification.appName,
            image:          notification.image,
            expireTimeout:  notification.expireTimeout,
            urgency:        notification.urgency,
            resident:       notification.resident,
            hasActionIcons: notification.hasActionIcons
        })
        root.list = [comp, ...root.list]
    }

    function dismiss(notif) {
        notif.close()
    }

    function dismissAll() {
        for (const n of root.list.slice()) {
            n.close()
        }
        root.list = []
    }

    Component {
        id: notifComp
        NotifData {}
    }
}
