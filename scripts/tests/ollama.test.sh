#!/usr/bin/env bash
# Tests for the Ollama setup (story 11): the service drop-ins the repo ships
# and bootstrap installs, and the doc that names where models live. The live_*
# tests compare the repo with this machine.
# Usage: scripts/tests/ollama.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
BOOTSTRAP="${BOOTSTRAP:-$ROOT/dotfiles/bootstrap.sh}"
REPO_DROPINS="$ROOT/system/systemd/ollama.service.d"
LIVE_DROPINS="${LIVE_DROPINS:-/etc/systemd/system/ollama.service.d}"
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

test_bootstrap_installs_dropins() {
    # The download tweak (one transfer stream, so a model pull does not
    # saturate the Wi-Fi) lives in the repo and bootstrap copies it in place.
    assert_eq "repo download.conf limits pulls to one stream" \
        'Environment="OLLAMA_MAX_TRANSFER_STREAMS=1"' \
        "$(grep -h '^Environment=' "$REPO_DROPINS/download.conf" 2>/dev/null || echo missing)"
    assert_eq "bootstrap copies the repo drop-ins to $LIVE_DROPINS" yes \
        "$(grep -v '^\s*#' "$BOOTSTRAP" | grep -cE "cp .*system/systemd/ollama\.service\.d/.* $LIVE_DROPINS" |
            awk '{print ($1 > 0) ? "yes" : "no"}')"
}

STORY12_DROPINS="igpu.conf" # device/acceleration settings: story 12 decides them

test_live_dropins_match_repo() {
    # Every drop-in this machine runs Ollama with is in the repo, byte for
    # byte, and the repo ships nothing the machine does not run - except the
    # acceleration drop-ins left to story 12.
    local live repo f diffs=""
    live=$(find "$LIVE_DROPINS" -maxdepth 1 -name '*.conf' -printf '%f\n' 2>/dev/null |
        grep -vxF "$STORY12_DROPINS" | sort | tr '\n' ' ')
    repo=$(find "$REPO_DROPINS" -maxdepth 1 -name '*.conf' -printf '%f\n' 2>/dev/null | sort | tr '\n' ' ')
    assert_eq "live drop-ins (minus story 12's) = repo drop-ins" "download.conf " "$live"
    assert_eq "repo drop-ins" "download.conf " "$repo"
    for f in $repo; do
        cmp -s "$LIVE_DROPINS/$f" "$REPO_DROPINS/$f" || diffs+="$f "
    done
    assert_eq "live drop-ins identical to the repo" none "${diffs:-none}"
    assert_eq "ollama.service enabled" enabled "$(systemctl is-enabled ollama 2>/dev/null)"
    assert_eq "ollama.service active" active "$(systemctl is-active ollama 2>/dev/null)"
}

POST_INSTALL="${POST_INSTALL:-$ROOT/backup/references/post-install.md}"

test_live_models_doc() {
    # After a reinstall the doc must say where models live and how to get
    # back every model pulled on this machine today, with its size.
    local models name size missing=""
    assert_eq "post-install names the model store" yes \
        "$(grep -cF '/var/lib/ollama' "$POST_INSTALL" 2>/dev/null | awk '{print ($1 > 0) ? "yes" : "no"}')"
    models=$(ollama list 2>/dev/null | awk 'NR > 1 {print $1 "|" $3 " " $4}')
    assert_eq "ollama lists pulled models" yes "$([[ -n $models ]] && echo yes || echo no)"
    while IFS='|' read -r name size; do
        [[ -z $name ]] && continue
        grep -F "ollama pull $name" "$POST_INSTALL" 2>/dev/null | grep -qF "$size" || missing+="$name($size) "
    done <<<"$models"
    assert_eq "post-install pulls every local model, with its size" none "${missing:-none}"
}

all_tests=(test_bootstrap_installs_dropins test_live_dropins_match_repo test_live_models_doc)
for t in "${@:-${all_tests[@]}}"; do
    echo "$t"
    "$t"
done
((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
