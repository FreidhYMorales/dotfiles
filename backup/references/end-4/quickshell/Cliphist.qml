// Servicio Quickshell para cliphist — end-4/dots-hyprland
// Clave: IpcHandler "cliphistService" → permite notificar en tiempo real desde el autostart.
//
// En execs.lua de Hyprland:
//   exec-once = wl-paste --type text --watch bash -c "cliphist store; qs ipc call cliphistService update"
//   exec-once = wl-paste --type image --watch bash -c "cliphist store; qs ipc call cliphistService update"
//
// Esto elimina el polling — Quickshell se actualiza solo cuando hay algo nuevo en el clipboard.
// También incluye fuzzy search, superpaste (pegar N entradas consecutivas), y modo delete.
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property string cliphistBinary: "cliphist"
    property list<string> entries: []

    function refresh() {
        readProc.buffer = []
        readProc.running = true
    }

    function copy(entry) {
        Quickshell.execDetached(["bash", "-c",
            `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy`
        ]);
    }

    function deleteEntry(entry) {
        deleteProc.deleteEntry(entry);
    }

    function wipe() {
        wipeProc.running = true;
    }

    // Pegar N entradas consecutivas con delay entre cada una (ydotool)
    function superpaste(count) {
        const targetEntries = entries.slice(0, count)
        const pasteDelay = 0.05
        const pressPaste = "ydotool key -d 1 29:1 47:1 47:0 29:0"
        const cmds = [...targetEntries].reverse().map(e =>
            `printf '${StringUtils.shellSingleQuoteEscape(e)}' | ${root.cliphistBinary} decode | wl-copy && sleep ${pasteDelay} && ${pressPaste}`
        )
        Quickshell.execDetached(["bash", "-c", cmds.join(` && sleep ${pasteDelay} && `)]);
    }

    // ← CLAVE: IPC handler para actualización en tiempo real sin polling
    IpcHandler {
        target: "cliphistService"
        function update(): void { root.refresh() }
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() { delayTimer.restart() }
    }

    Timer {
        id: delayTimer
        interval: 50  // ms — race condition entre wl-paste y cliphist store
        onTriggered: root.refresh()
    }

    Process {
        id: readProc
        property list<string> buffer: []
        command: [root.cliphistBinary, "list"]
        stdout: SplitParser { onRead: (line) => readProc.buffer.push(line) }
        onExited: (code, _) => { if (code === 0) root.entries = readProc.buffer }
    }

    Process {
        id: deleteProc
        property string entry: ""
        command: ["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(deleteProc.entry)}' | ${root.cliphistBinary} delete`]
        function deleteEntry(e) { entry = e; running = true; entry = "" }
        onExited: root.refresh()
    }

    Process {
        id: wipeProc
        command: [root.cliphistBinary, "wipe"]
        onExited: root.refresh()
    }
}
