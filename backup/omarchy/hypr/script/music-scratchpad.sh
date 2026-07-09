#!/bin/bash
if hyprctl clients -j | jq -e '[.[] | select(.class == "org.omarchy.ncmpcpp")] | length > 0' > /dev/null 2>&1; then
    hyprctl dispatch togglespecialworkspace music
else
    omarchy-launch-tui ncmpcpp
fi
