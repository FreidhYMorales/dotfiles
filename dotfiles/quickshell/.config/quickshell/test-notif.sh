#!/usr/bin/env bash
# Quick notification tester for the Quickshell NotifToast.
# Usage: ./test-notif.sh [type]
#   types: normal (default), critical, long, noicon

TYPE="${1:-normal}"

case "$TYPE" in
  normal)
    notify-send -a "Firefox" -i "firefox" \
      "Tab loaded" "rust-lang.org — Empowering everyone to build reliable and efficient software."
    ;;
  critical)
    notify-send -a "System" -u critical \
      "Battery critical" "Battery at 5% — plug in the charger now."
    ;;
  long)
    notify-send -a "Discord" -i "discord" \
      "New message from deadlock" \
      "Hey, are you around? I wanted to discuss the PR we opened yesterday and check if there are any blockers before the review."
    ;;
  noicon)
    notify-send "Plain notification" "No app icon, no urgency. Just a basic test."
    ;;
  *)
    echo "Types: normal | critical | long | noicon"
    exit 1
    ;;
esac

echo "Sent: $TYPE"
