#!/bin/bash
if hyprctl clients -j | jq -e '[.[] | select(.workspace.name == "special:messaging")] | length > 0' > /dev/null 2>&1; then
    hyprctl dispatch togglespecialworkspace messaging
else
    omarchy-launch-webapp "https://web.whatsapp.com/" &
fi
