#!/usr/bin/env bash
# Integration tests for the user scripts and user systemd units (story 08).
# Reads the repo's packages; the live_* tests check this machine's deployed
# state ($HOME, the user systemd manager).
# Usage: scripts/tests/scripts-units.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
DOTFILES="$ROOT/dotfiles"
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

repo_units() { # -> every user unit file the repo deploys
    find "$DOTFILES"/*/.config/systemd/user -maxdepth 1 -type f \
        \( -name '*.service' -o -name '*.path' -o -name '*.timer' -o -name '*.socket' \) 2>/dev/null | sort
}

test_unit_paths_exist() {
    # Every path a repo unit runs or watches (%h = $HOME) must exist once the
    # repo is deployed; a unit pointing at a removed tool is dead weight.
    local unit line token missing=()
    while read -r unit; do
        while read -r line; do
            for token in ${line#*=}; do
                token=${token//%h/$HOME}
                [[ $token == /* && ! -e $token ]] && missing+=("$(basename "$unit"):$token")
            done
        done < <(grep -E '^(ExecStart|ExecStartPre|ExecStop|PathModified|PathChanged|PathExists)=' "$unit")
    done < <(repo_units)
    assert_eq "repo user units only reference existing paths" "none" "${missing[*]:-none}"
}

test_live_units_running() {
    # Every repo unit that installs itself must be enabled and running in the
    # user session; a deployed unit that is off or failed is dead or broken.
    local unit name state=()
    while read -r unit; do
        grep -q '^\[Install\]' "$unit" || continue
        name=$(basename "$unit")
        state+=("$name:$(systemctl --user is-enabled "$name" 2>/dev/null)/$(systemctl --user is-active "$name" 2>/dev/null)")
    done < <(repo_units)
    assert_eq "repo user units are enabled and running" \
        "matugen-server.service:enabled/active" "${state[*]:-none}"
}

DROPPED_SCRIPTS=(battery-remaining battery-status battery-time brightness-display
    brightness-keyboard wsaction get-location libreoffice soffice)

test_dropped_scripts_gone() {
    # Scripts nothing calls, dropped by the owner, must be gone from both the
    # package and the deployed ~/.local/bin.
    local s left=()
    for s in "${DROPPED_SCRIPTS[@]}"; do
        [[ -e $DOTFILES/scripts/.local/bin/$s ]] && left+=("repo:$s")
        [[ -e $HOME/.local/bin/$s || -L $HOME/.local/bin/$s ]] && left+=("home:$s")
    done
    assert_eq "dropped scripts are gone (9 checked)" "9 none" "${#DROPPED_SCRIPTS[@]} ${left[*]:-none}"
}

all_tests=(test_unit_paths_exist test_live_units_running test_dropped_scripts_gone)
for t in "${@:-${all_tests[@]}}"; do
    echo "$t"
    "$t"
done
((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
