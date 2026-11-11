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

mpd_cmd() { # command... -> mpd's raw protocol reply (live mpd on 127.0.0.1:6600)
    bash -c 'exec 3<>/dev/tcp/127.0.0.1/6600 || exit 1
        printf "%s\n" "$@" close >&3
        timeout 3 cat <&3' _ "$@" 2>/dev/null
}

test_live_mpd_keeps_its_library_after_migration() {
    # After moving the database to ~/.local/state/mpd, the running mpd (started
    # through the unit and its drop-in) still knows every track in ~/Music.
    local expected actual
    expected=$(fd -t f -e mp3 -e flac -e m4a -e ogg -e opus -e wav . "$HOME/Music" | wc -l)
    actual=$(mpd_cmd stats | rg -o -r '$1' '^songs: (\d+)')
    assert_eq "music files in ~/Music are non-zero" "yes" "$([[ $expected -gt 0 ]] && echo yes || echo no)"
    assert_eq "mpd database file in the state dir" "yes" \
        "$([[ -s $HOME/.local/state/mpd/database ]] && echo yes || echo no)"
    assert_eq "mpd unit loads the state drop-in" \
        "$HOME/.config/systemd/user/mpd.service.d/state.conf" \
        "$(systemctl --user show mpd -p DropInPaths --value)"
    assert_eq "mpd knows every track in ~/Music" "$expected" "$actual"
}

test_live_mpd_saves_a_playlist() {
    # Saving the queue as a playlist (what ncmpcpp does) lands an .m3u in the
    # state dir, and mpd's log has no missing-playlists-folder error since it
    # last started. The test playlist is removed afterwards.
    local name="flow-story06-test" file reply errors
    file="$HOME/.local/state/mpd/playlists/$name.m3u"
    reply=$(mpd_cmd "save \"$name\"" | tail -1)
    assert_eq "mpd accepts saving a playlist" "OK" "$reply"
    assert_eq "playlist file written to the state dir" "yes" "$([[ -f $file ]] && echo yes || echo no)"
    mpd_cmd "rm \"$name\"" >/dev/null
    errors=$(journalctl --user -u mpd -o cat --no-pager \
        --since "$(systemctl --user show mpd -p ActiveEnterTimestamp --value)" |
        rg -c 'playlists: No such file')
    assert_eq "mpd log reports no missing playlists folder" "0" "${errors:-0}"
}

test_mpv_config_parses() {
    # The installed mpv accepts every option in the repo's mpv.conf: it plays
    # one frame of a generated test source with no option errors. Video and
    # audio go to null outputs so the test needs no window or sound, and
    # keep-open is overridden so mpv exits at the end instead of waiting.
    local out status
    out=$(timeout 20 mpv --no-config --include="$DOTFILES/mpv/.config/mpv/mpv.conf" \
        --vo=null --ao=null --keep-open=no --frames=1 --msg-level=all=warn \
        "av://lavfi:testsrc=duration=1" 2>&1)
    status=$?
    assert_eq "mpv exits cleanly with the repo config" "0" "$status"
    assert_eq "mpv reports no option errors" "" \
        "$(printf '%s\n' "$out" | rg -i 'error parsing|unknown|invalid|not found|deprecated')"
}

tests=("$@")
if [[ ${#tests[@]} -eq 0 ]]; then
    mapfile -t tests < <(declare -F | awk '$3 ~ /^test_/ {print $3}')
fi
for t in "${tests[@]}"; do
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
