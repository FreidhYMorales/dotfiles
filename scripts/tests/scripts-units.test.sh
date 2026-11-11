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

# Kept scripts and the commands each needs (from their headers and scripts/README.md).
declare -A KEPT_DEPS=(
    [clipboard]="cliphist wl-copy fuzzel"
    [launch-or-focus]="hyprctl jq setsid"
    [mute-toggle]="wpctl"
    [notification-send]="notify-send"
    [ocr]="grim slurp hyprpicker tesseract wl-copy"
    [record]="gpu-screen-recorder slurp jq"
    [reminder]="systemd-run notify-send notification-send"
    [screenshot]="grim slurp hyprpicker wl-copy satty"
    [webapp-install]="curl"
    [webapp-launch]="xdg-settings uwsm-app chromium"
    [webapp-remove]="find"
    [webapp-restore]="webapp-install"
)

test_live_kept_scripts_work() {
    # Every kept script is in the package, its commands are installed, and it
    # passes shellcheck at error level.
    local s d broken=()
    for s in "${!KEPT_DEPS[@]}"; do
        [[ -x $DOTFILES/scripts/.local/bin/$s ]] || { broken+=("$s:missing"); continue; }
        for d in ${KEPT_DEPS[$s]}; do
            command -v "$d" >/dev/null || broken+=("$s:needs-$d")
        done
        shellcheck -S error "$DOTFILES/scripts/.local/bin/$s" >/dev/null || broken+=("$s:shellcheck")
    done
    assert_eq "12 kept scripts have their deps and pass shellcheck" \
        "12 none" "${#KEPT_DEPS[@]} ${broken[*]:-none}"
}

test_live_no_dangling_links() {
    # A symlink left behind by a removed package shows up as a broken command,
    # launcher entry or unit; none may point at a missing target.
    local dangling
    dangling=$(find -L "$HOME/.local/bin" "$HOME/.local/share/applications" \
        "$HOME/.config/systemd/user" -maxdepth 1 -type l 2>/dev/null | sort | tr '\n' ' ')
    assert_eq "no dangling symlinks in bin, applications, user units" "none" "${dangling:-none}"
}

all_tests=(test_unit_paths_exist test_live_units_running test_dropped_scripts_gone
    test_live_kept_scripts_work test_live_no_dangling_links)
for t in "${@:-${all_tests[@]}}"; do
    echo "$t"
    "$t"
done
((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
