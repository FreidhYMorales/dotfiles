#!/usr/bin/env bash
# Integration tests for the root-level configs under system/ (story 09).
# Reads the repo's system/ tree; the live_* tests check this machine's
# installed state (/etc, logind, the kernel). Nothing here needs root and
# nothing runs a PAM conversation (pam_faillock would lock the account).
# Usage: scripts/tests/system.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
SYSTEM="$ROOT/system"
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

test_live_sleep_inhibitor() {
    # The session must hold a logind delay lock on sleep so it can lock the
    # screen before any suspend (the notch shell's SleepLock); without it a
    # lid close resumes to an unlocked desktop.
    local held
    held=$(systemd-inhibit --list --no-pager 2>/dev/null |
        awk -v uid="$(id -u)" '$2 == uid && $6 == "sleep" && $NF == "delay" {print $1}' | sort -u)
    assert_eq "session holds a sleep delay inhibitor" "notch" "${held:-none}"
}

test_hook_dropped() {
    # The root system-sleep hook is dead (systemd freezes user.slice while
    # sleep hooks run, so its Quickshell IPC can never answer); the repo must
    # neither ship it nor install or describe it.
    local refs
    refs=$(grep -rlE 'lock-before-sleep|system-sleep' "$SYSTEM" "$ROOT/dotfiles/bootstrap.sh" 2>/dev/null |
        sed "s|$ROOT/||" | sort | tr '\n' ' ')
    assert_eq "no system-sleep hook shipped or referenced" "none" "${refs:-none}"
}

all_tests=(test_live_sleep_inhibitor test_hook_dropped)
for t in "${@:-${all_tests[@]}}"; do
    echo "$t"
    "$t"
done
((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
