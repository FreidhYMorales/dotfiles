import Quickshell.Io

// IPC-based shortcut. Functions defined on this handler are callable via:
//   qs ipc call <target> <functionName>
// Note: onMessage is NOT used — qs ipc call invokes QML functions by name directly.
IpcHandler {
    property string description: ""
}
