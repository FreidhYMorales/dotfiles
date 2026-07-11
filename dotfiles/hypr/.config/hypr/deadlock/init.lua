require("deadlock.animations")
require("deadlock.decorations")
require("deadlock.env")
require("deadlock.execs")
require("deadlock.general")
require("deadlock.input")
require("deadlock.keybinds")
require("deadlock.rule")
require("deadlock.xwayland")

-- Only apply NVIDIA env vars when an NVIDIA GPU is actually present.
-- Avoids breaking GBM/render on Intel or AMD-only machines.
local lspci = io.popen("lspci 2>/dev/null")
if lspci then
    local out = lspci:read("*a")
    lspci:close()
    if out:lower():find("nvidia") then
        require("deadlock.nvidia")
    end
end
