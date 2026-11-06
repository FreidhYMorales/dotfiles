pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// Replaces polkit-gnome-authentication-agent-1 (GTK, visually mismatched —
// see hypr/.config/hypr/deadlock/execs.lua) with a themed prompt rendered
// inside the launcher itself (modules/launcher/LauncherContent.qml "polkit"
// mode + PolkitForm.qml). Only one polkit agent can be registered per
// session — this one takes over that role entirely.
//
// `flow` is generic (message/inputPrompt/iconName come from whatever action
// triggered the request — fprintd enroll, udisks mount, etc.), so the same
// UI handles every polkit request in the system, not just fingerprint
// enrollment.
Singleton {
    id: root

    readonly property bool isRegistered: agent.isRegistered
    readonly property bool active: agent.isActive
    readonly property var flow: agent.flow

    function submit(value) {
        if (root.flow) root.flow.submit(value)
    }

    function cancel() {
        if (root.flow) root.flow.cancelAuthenticationRequest()
    }

    PolkitAgent {
        id: agent
    }
}
