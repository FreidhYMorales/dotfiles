// Servicio Quickshell para el anti-flashbang shader — end-4/dots-hyprland
// Controla activación/desactivación del GLSL shader en runtime vía HyprlandConfig.
// Tres estados: disabled → weak → strong → disabled (cycle())
//
// IMPORTANTE para NVIDIA: debug:damage_tracking = 1 (solo monitor, no global)
// evita flashes extraños al activar el shader con GPU NVIDIA.
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common.models.hyprland  // HyprlandConfig, HyprlandConfigOption

Singleton {
    id: root

    readonly property string shaderPath: Quickshell.shellPath("services/hyprlandAntiFlashbangShader/anti-flashbang.glsl")
    readonly property string weakShaderPath: Quickshell.shellPath("services/hyprlandAntiFlashbangShader/anti-flashbang-weak.glsl")
    property bool enabled: confOpt.value == shaderPath || weak
    property bool weak: confOpt.value == weakShaderPath

    function enable() {
        HyprlandConfig.setMany({
            "decoration:screen_shader": root.shaderPath,
            "debug:damage_tracking": 1,
        });
    }

    function enableWeak() {
        HyprlandConfig.setMany({
            "decoration:screen_shader": root.weakShaderPath,
            "debug:damage_tracking": 1,
        });
    }

    function disable() {
        HyprlandConfig.resetMany([
            "decoration:screen_shader",
            "debug:damage_tracking"
        ]);
    }

    function toggle() {
        if (root.enabled) disable()
        else enable()
    }

    function cycle() {
        if (!enabled)    enableWeak()
        else if (weak)   enable()
        else             disable()
    }

    HyprlandConfigOption {
        id: confOpt
        key: "decoration:screen_shader"
    }
}
