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

test_live_dropins_match_repo() {
    # Every drop-in this machine runs Ollama with is in the repo, byte for
    # byte, and the repo ships nothing the machine does not run. Story 12
    # folded in igpu.conf, which story 11 had left out.
    local live repo f diffs=""
    live=$(find "$LIVE_DROPINS" -maxdepth 1 -name '*.conf' -printf '%f\n' 2>/dev/null | sort | tr '\n' ' ')
    repo=$(find "$REPO_DROPINS" -maxdepth 1 -name '*.conf' -printf '%f\n' 2>/dev/null | sort | tr '\n' ' ')
    assert_eq "live drop-ins = repo drop-ins" "download.conf igpu.conf " "$live"
    assert_eq "repo drop-ins" "download.conf igpu.conf " "$repo"
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

EXCLUDED="${EXCLUDED:-$ROOT/dotfiles/bootstrap-excluded.txt}"

test_bootstrap_installs_vulkan_backend() {
    # Story 12: without the Vulkan backend Ollama runs on the CPU only.
    local n
    n=$(awk '{ if (sub(/\\$/, "")) { buf = buf $0 " "; next } print buf $0; buf = "" }' "$BOOTSTRAP" |
        grep -oE '(pacman|yay) -S --needed --noconfirm[^|;&]*' | tr -s ' ' '\n' | grep -cxF ollama-vulkan)
    assert_eq "bootstrap installs ollama-vulkan" yes "$( ((n > 0)) && echo yes || echo no)"
    assert_eq "ollama-vulkan not in the exclusion list" no \
        "$( (($(grep -cE '^ollama-vulkan([[:space:]]|$)' "$EXCLUDED") > 0)) && echo yes || echo no)"
}

test_repo_ships_igpu_dropin() {
    # Story 12: Ollama drops integrated GPUs unless OLLAMA_IGPU_ENABLE=1
    # ("dropping integrated GPU; to enable, set OLLAMA_IGPU_ENABLE=1").
    assert_eq "repo igpu.conf enables the integrated GPU" 'Environment="OLLAMA_IGPU_ENABLE=1"' \
        "$(grep -h '^Environment=' "$REPO_DROPINS/igpu.conf" 2>/dev/null || echo missing)"
}

IGPU_MODEL="${IGPU_MODEL:-gpt-oss:20b}"

test_live_model_runs_on_igpu() {
    # Story 12: a loaded model runs fully on the Arc iGPU, not on the CPU.
    curl -s --max-time 300 http://127.0.0.1:11434/api/generate \
        -d "{\"model\":\"$IGPU_MODEL\",\"prompt\":\"hi\",\"stream\":false,\"keep_alive\":\"60s\",\"options\":{\"num_predict\":1}}" \
        >/dev/null
    assert_eq "$IGPU_MODEL runs on the GPU" "100% GPU" \
        "$(ollama ps 2>/dev/null | awk -v m="$IGPU_MODEL" '$1 == m { for (i = 1; i <= NF; i++) if ($i == "GPU" || $i == "CPU" || $i == "CPU/GPU") { print $(i - 1), $i; exit } }')"
}

doc_row() { # label -> "tok/s W" from the post-install benchmark table row "| <label> | N tok/s | N W |"
    awk -F'|' -v l="$1" '{ gsub(/^ +| +$/, "", $2) } $2 == l {
        t = $3; w = $4; gsub(/[^0-9.]/, "", t); gsub(/[^0-9.]/, "", w); print t, w; exit }' "$POST_INSTALL"
}

test_models_doc_has_igpu_vs_cpu() {
    # Story 12: the doc gives tokens/s and battery draw on the iGPU and on the
    # CPU alone, and the default (the iGPU) is the faster one.
    local igpu cpu
    igpu=$(doc_row "iGPU (default)")
    cpu=$(doc_row "CPU only")
    assert_eq "iGPU row has tok/s and W" yes "$([[ $igpu =~ ^[0-9.]+\ [0-9.]+$ ]] && echo yes || echo "no (${igpu:-missing})")"
    assert_eq "CPU row has tok/s and W" yes "$([[ $cpu =~ ^[0-9.]+\ [0-9.]+$ ]] && echo yes || echo "no (${cpu:-missing})")"
    assert_eq "the iGPU default is faster than the CPU" yes \
        "$(awk -v a="${igpu%% *}" -v b="${cpu%% *}" 'BEGIN { print (a + 0 > b + 0 && b + 0 > 0) ? "yes" : "no" }')"
}

test_docs_do_not_skip_gpu_on_thinkpad() {
    # Story 12: --no-gpu skips vulkan-intel, so Ollama would fall back to the
    # CPU; the ThinkPad reinstall must take the lspci auto-detect path.
    assert_eq "CLAUDE.md does not advise --no-gpu on the ThinkPad" 0 \
        "$(grep -i -- '--no-gpu' "$ROOT/CLAUDE.md" | grep -ciE 'usar en thinkpad|use on (the )?thinkpad')"
}

all_tests=(test_bootstrap_installs_dropins test_live_dropins_match_repo test_live_models_doc
    test_bootstrap_installs_vulkan_backend test_repo_ships_igpu_dropin test_live_model_runs_on_igpu
    test_models_doc_has_igpu_vs_cpu test_docs_do_not_skip_gpu_on_thinkpad)
for t in "${@:-${all_tests[@]}}"; do
    echo "$t"
    "$t"
done
((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
