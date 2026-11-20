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

PAM_DIR="${PAM_DIR:-/etc/pam.d}" # installed PAM services (override to point at a copy)

auth_lines() { # file -> its auth lines, whitespace collapsed
    grep -E '^-?auth' "$1" | tr -s ' \t' ' '
}

test_live_lockscreen_pam_stacks() {
    # Lockscreen password: system-auth's own auth stack minus pam_fprintd, so a
    # password attempt never waits on, nor is bypassed by, the reader.
    # Lockscreen fingerprint: a single scan per conversation, nothing else.
    local want got
    want=$(auth_lines "$PAM_DIR/system-auth" | grep -v pam_fprintd)
    got=$(auth_lines "$PAM_DIR/quickshell-password")
    assert_eq "quickshell-password = system-auth auth without fingerprint" "$want" "$got"
    assert_eq "quickshell-fprint is one fingerprint scan" \
        "auth required pam_fprintd.so max-tries=1" "$(auth_lines "$PAM_DIR/quickshell-fprint")"
}

all_tests=(test_live_sleep_inhibitor test_hook_dropped test_live_lockscreen_pam_stacks)
for t in "${@:-${all_tests[@]}}"; do
    echo "$t"
    "$t"
done
((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
