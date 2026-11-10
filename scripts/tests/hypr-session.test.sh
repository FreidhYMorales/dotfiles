#!/usr/bin/env bash
# Integration tests for the Hyprland session: hypr, uwsm, xdg-portal,
# termfilechooser (story 04). Reads the repo's config files; the keybind test
# also checks commands and Quickshell IPC targets against the live session.
# Usage: scripts/tests/hypr-session.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
HYPR="$ROOT/dotfiles/hypr/.config/hypr"
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

test_hypr_package_holds_only_files_the_session_reads() {
    # hyprland.lua requires monitors.lua and deadlock/init.lua, which requires
    # every deadlock/*.lua (nvidia.lua only on NVIDIA machines); bootstrap.sh
    # seeds the default wallpaper from assets/arch.png. Generated, gitignored
    # files (deadlock/colors.lua, hyprpaper.conf) are not part of the package.
    local expected actual
    expected="assets/arch.png
deadlock/animations.lua
deadlock/decorations.lua
deadlock/env.lua
deadlock/execs.lua
deadlock/general.lua
deadlock/gestures.lua
deadlock/init.lua
deadlock/input.lua
deadlock/keybinds.lua
deadlock/nvidia.lua
deadlock/rule.lua
deadlock/xwayland.lua
hyprland.lua
monitors.lua"
    actual=$(git -C "$HYPR" ls-files --cached --others --exclude-standard | LC_ALL=C sort)
    assert_eq "hypr package holds only files the session reads" "$expected" "$actual"
}

test_autostart_runs_through_uwsm_without_duplicates() {
    # Loads the real execs.lua with a fake hl table that prints every command
    # started on hyprland.start. Each one must go through `uwsm app --`; the
    # environment export (uwsm), gnome-keyring (PAM auto_start) and
    # termfilechooser (D-Bus activated) are never started by hand.
    local actual
    actual=$(lua -e '
        hl = { exec_cmd = function(cmd) print(cmd) end,
               on = function(_, callback) callback() end }
        dofile(arg[1])' "$HYPR/deadlock/execs.lua" 2>&1)
    assert_eq "autostart runs each app once through uwsm" \
        "uwsm app -- sh -c 'config=\"\${XDG_STATE_HOME:-\$HOME/.local/state}/quickshell-notch/hyprpaper.conf\"; if [ -f \"\$config\" ]; then exec hyprpaper -c \"\$config\"; else exec hyprpaper; fi'
uwsm app -- wl-paste --type text --watch cliphist store
uwsm app -- wl-paste --type image --watch cliphist store
uwsm app -- qs -c notch
uwsm app -- trash-empty 30
uwsm app -- mpris-proxy" \
        "$actual"
}

test_every_keybind_runs_something_that_exists() {
    # Loads the real keybinds.lua with a fake hl table and lists the command of
    # every exec bind. Each program must resolve on the session PATH (uwsm
    # prepends ~/.local/bin), and each `qs -c notch ipc call <target> <fn>`
    # must name a function the running notch shell exposes.
    local cmds ipc missing="" n=0 cmd prog target fn
    cmds=$(lua -e '
        local function proxy()
            return setmetatable({}, { __index = function() return proxy() end,
                                      __call = function() return proxy() end })
        end
        hl = { dsp = proxy(), bind = function(_, action)
            if type(action) == "table" and rawget(action, "exec") then print(action.exec) end
        end }
        rawset(hl.dsp, "exec_cmd", function(cmd) return { exec = cmd } end)
        dofile(arg[1])' "$HYPR/deadlock/keybinds.lua" 2>&1)
    ipc=$(qs -c notch ipc show 2>/dev/null)
    while IFS= read -r cmd; do
        [[ -z "$cmd" ]] && continue
        n=$((n + 1))
        prog=${cmd%% *}
        PATH="$HOME/.local/bin:$PATH" command -v "$prog" >/dev/null || missing+="$cmd"$'\n'
        if [[ "$cmd" =~ ^qs\ -c\ notch\ ipc\ call\ ([^ ]+)\ ([^ ]+) ]]; then
            target=${BASH_REMATCH[1]} fn=${BASH_REMATCH[2]}
            awk -v t="$target" -v f="$fn" '$1 == "target" { cur = $2 }
                cur == t && $1 == "function" && index($2, f "(") == 1 { found = 1 }
                END { exit !found }' <<<"$ipc" || missing+="$cmd"$'\n'
        fi
    done <<<"$cmds"
    assert_eq "keybinds file yields exec binds to check" "yes" "$([[ $n -gt 0 ]] && echo yes || echo "no ($cmds)")"
    assert_eq "every exec keybind runs an existing command or IPC target" "" "${missing%$'\n'}"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
