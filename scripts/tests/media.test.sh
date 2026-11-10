#!/usr/bin/env bash
# Integration tests for the media setup: mpv, mpd, ncmpcpp, wiremix (story 06).
# Reads the repo's packages; the live_* tests check this machine's deployed
# configs and the running mpd.
# Usage: scripts/tests/media.test.sh [test_name ...]   (no args = all tests)
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

mpd_conf_value() { # key -> value of the first `key "value"` line in mpd.conf
    rg -o -r '$1' "^$1\\s+\"([^\"]*)\"" "$DOTFILES/mpd/.config/mpd/mpd.conf" 2>/dev/null |
        head -1
}

test_mpd_runtime_lives_in_state_dir() {
    # mpd's database, state, stickers and playlists live in ~/.local/state/mpd
    # and its log goes to journald, so ~/.config/mpd holds only config and
    # running mpd never writes into the repo. Lists what is on disk in the
    # package (ignored files included), not just what git tracks.
    local key actual=""
    for key in db_file state_file sticker_file playlist_directory log_file; do
        actual+="$key=$(mpd_conf_value "$key") "
    done
    assert_eq "mpd runtime paths" \
        "db_file=~/.local/state/mpd/database state_file=~/.local/state/mpd/state sticker_file=~/.local/state/mpd/sticker.sql playlist_directory=~/.local/state/mpd/playlists log_file=syslog" \
        "${actual% }"
    actual=$(cd "$DOTFILES/mpd" && fd . --hidden --no-ignore --type f | LC_ALL=C sort | xargs)
    assert_eq "mpd package holds only config" \
        ".config/mpd/mpd.conf .config/systemd/user/mpd.service.d/state.conf" "$actual"
}

test_deploy_keeps_mpd_dropin_dir_real() {
    # systemd ignores a drop-in directory that is itself a symlink, so the unit
    # would never create mpd's state dirs and mpd would fail to open its
    # database. On a fresh HOME (no ~/.config/systemd yet) deploy.sh must leave
    # mpd.service.d a real directory that links only state.conf.
    local home dir actual
    home=$(mktemp -d)
    HOME="$home" "$DOTFILES/deploy.sh" mpd >/dev/null 2>&1
    dir="$home/.config/systemd/user/mpd.service.d"
    actual="$([[ "$(realpath "$dir" 2>/dev/null)" == "$(realpath "$home")/.config/systemd/user/mpd.service.d" ]] && echo real-dir || echo not-real-dir)"
    actual+=" $(cd "$dir" 2>/dev/null && fd . --max-depth 1 --type symlink | LC_ALL=C sort | xargs)"
    rm -rf "$home"
    assert_eq "deploy leaves mpd.service.d a real directory linking only state.conf" \
        "real-dir state.conf" "$actual"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
