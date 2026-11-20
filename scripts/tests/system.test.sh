#!/usr/bin/env bash
# Integration tests for the root-level configs under system/ (story 09).
# Reads the repo's system/ tree; the live_* tests check this machine's
# installed state (/etc, logind, the kernel). Nothing here needs root and
# nothing runs a PAM conversation (pam_faillock would lock the account).
# Usage: scripts/tests/system.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
SYSTEM="${SYSTEM_DIR:-$ROOT/system}" # override to point at a copy
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

auth_chain() { # service -> the auth modules it runs, following includes, in order
    local kind control module
    while read -r kind control module _; do
        if [[ $control == include || $control == substack ]]; then
            auth_chain "$module"
        else
            echo "$module"
        fi
    done < <(auth_lines "$PAM_DIR/$1" | sed 's/\[[^]]*\]/bracket/')
}

test_live_sudo_tty_fprint_or_password() {
    # sudo and a TTY login accept the fingerprint or the password: a
    # sufficient pam_fprintd runs before pam_unix in both chains.
    local svc chain got=()
    for svc in sudo login; do
        chain=$(auth_chain "$svc" | grep -E '^pam_(fprintd|unix)\.so$' | tr '\n' ' ')
        got+=("$svc: $chain")
    done
    assert_eq "sudo and login try fingerprint, then password" \
        "sudo: pam_fprintd.so pam_unix.so |login: pam_fprintd.so pam_unix.so " "$(IFS='|'; echo "${got[*]}")"
    assert_eq "system-auth fingerprint is sufficient" "sufficient" \
        "$(auth_lines "$PAM_DIR/system-auth" | awk '$3 == "pam_fprintd.so" {print $2}')"
}

test_sddm_pam_password_only() {
    # The SDDM greeter takes the password only (no fingerprint) and hands it
    # to the keyring, so every login unlocks it.
    local f="$SYSTEM/pam.d/sddm" mods
    mods=$(grep -E '^-?(auth|session)' "$f" | tr -s ' \t' ' ' | sed 's/\[[^]]*\]/bracket/' |
        grep -E 'pam_(fprintd|unix|gnome_keyring)\.so' | awk '{print $1 ":" $3}' | tr '\n' ' ')
    assert_eq "SDDM: password then keyring, no fingerprint" \
        "auth:pam_unix.so -auth:pam_gnome_keyring.so -session:pam_gnome_keyring.so " "$mods"
}

# Repo file -> installed copy, for every system/ file in live use.
declare -A INSTALLED=(
    [logind/logind.conf.d/deadlock.conf]=/etc/systemd/logind.conf.d/deadlock.conf
    [systemd/sleep.conf.d/deadlock.conf]=/etc/systemd/sleep.conf.d/deadlock.conf
    [udev/rules.d/90-power-profile-ac.rules]=/etc/udev/rules.d/90-power-profile-ac.rules
    [udev/rules.d/92-mute-leds.rules]=/etc/udev/rules.d/92-mute-leds.rules
    [pam.d/quickshell-password]=/etc/pam.d/quickshell-password
    [pam.d/quickshell-fprint]=/etc/pam.d/quickshell-fprint
    [pam.d/sddm]=/etc/pam.d/sddm
    [sddm/sddm.conf.d/deadlock.conf]=/etc/sddm.conf.d/deadlock.conf
)

test_live_matches_repo() {
    # What runs as root is what the repo says: every installed copy is
    # byte-identical to its repo file.
    local src drift=()
    for src in "${!INSTALLED[@]}"; do
        cmp -s "$SYSTEM/$src" "${INSTALLED[$src]}" || drift+=("${INSTALLED[$src]}")
    done
    assert_eq "installed system/ files match the repo (8 checked)" \
        "8 none" "${#INSTALLED[@]} $(printf '%s\n' "${drift[@]}" | sort | tr '\n' ' ' | sed 's/ $//;s/^$/none/')"
}

test_comments_reference_existing_paths() {
    # A comment that sends the reader to a repo file must point at one that
    # exists; a dangling pointer means the comment describes old behaviour.
    local refs missing=() ref
    mapfile -t refs < <(grep -rhoE '(dotfiles|system|auditorias|docs)/[A-Za-z0-9._/-]*[A-Za-z0-9_]' \
        "$SYSTEM" --exclude-dir=themes | sort -u)
    for ref in "${refs[@]}"; do
        [[ -e $ROOT/$ref ]] || missing+=("$ref")
    done
    assert_eq "system/ comments only name existing repo paths (${#refs[@]} found)" \
        "none" "${missing[*]:-none}"
}

test_live_hibernate_prereqs() {
    # Lid close runs suspend-then-hibernate (this machine only has s2idle,
    # which drains the battery): the kernel must know where to resume from,
    # that swap must be active, and logind must agree it can do it.
    local resume swaps
    resume=$(grep -oE 'resume=UUID=[0-9a-f-]+' /proc/cmdline | cut -d= -f3)
    # swapon hides UUIDs without root; lsblk reads them per active device.
    swaps=$(swapon --show=NAME --noheadings | xargs -r lsblk -no UUID 2>/dev/null)
    assert_eq "resume= names an active swap" "yes" \
        "$([[ -n $resume ]] && grep -qx "$resume" <<<"$swaps" && echo yes || echo "no (resume=${resume:-unset})")"
    # The busybox resume hook, or the systemd hook (story 20), which resumes
    # by itself from resume= on the cmdline.
    assert_eq "the initramfs can resume (resume or systemd hook)" "yes" \
        "$(grep -E '^HOOKS=' /etc/mkinitcpio.conf | grep -qwE 'resume|systemd' && echo yes || echo no)"
    assert_eq "only s2idle is available" "[s2idle]" "$(</sys/power/mem_sleep)"
    assert_eq "lid close on battery and AC" "suspend-then-hibernate suspend-then-hibernate" \
        "$(grep -E '^HandleLidSwitch(ExternalPower)?=' "$SYSTEM/logind/logind.conf.d/deadlock.conf" | cut -d= -f2 | tr '\n' ' ' | sed 's/ $//')"
    assert_eq "logind can suspend-then-hibernate" '"yes"' \
        "$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanSuspendThenHibernate 2>/dev/null | cut -d' ' -f2)"
}

all_tests=(test_live_sleep_inhibitor test_hook_dropped test_live_lockscreen_pam_stacks
    test_live_sudo_tty_fprint_or_password test_sddm_pam_password_only test_live_matches_repo
    test_comments_reference_existing_paths test_live_hibernate_prereqs)
for t in "${@:-${all_tests[@]}}"; do
    echo "$t"
    "$t"
done
((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
