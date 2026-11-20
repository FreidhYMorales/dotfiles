#!/usr/bin/env bash
# Tests for the TTY console font (story 16): bootstrap installs Terminus and
# sets it in vconsole.conf so the plain TTYs are readable at 2880x1800. The
# live_* tests check this machine.
# Usage: scripts/tests/console.test.sh [test_name ...]   (no args = all tests)
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
BOOTSTRAP="${BOOTSTRAP:-$ROOT/dotfiles/bootstrap.sh}"
FONT_LINE="FONT=ter-132b"
failures=0

assert_eq() { # name expected actual
    if [[ "$2" == "$3" ]]; then
        printf '  ok   %s\n' "$1"
    else
        printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
        failures=$((failures + 1))
    fi
}

console_step() { # -> the console font step of bootstrap.sh
    awk '/^step "Console font/ {on = 1; next} on && /^step / {exit} on' "$BOOTSTRAP"
}

run_console_step() { # vconsole-file [runs] -> runs the step on that file with sudo passed through
    local file=$1 runs=${2:-1} dir i
    dir=$(mktemp -d)
    mkdir -p "$dir/bin"
    printf '#!/usr/bin/env bash\n"$@"\n' >"$dir/bin/sudo"
    printf '#!/usr/bin/env bash\necho "$*" >>"%s/pacman.log"\n' "$dir" >"$dir/bin/pacman"
    chmod +x "$dir/bin/sudo" "$dir/bin/pacman"
    console_step >"$dir/step.sh"
    for ((i = 0; i < runs; i++)); do
        PATH="$dir/bin:$PATH" VCONSOLE="$file" bash -euo pipefail "$dir/step.sh" >/dev/null 2>&1
    done
    cat "$dir/pacman.log" 2>/dev/null
    rm -rf "$dir"
}

KEYMAP_LINES=$'KEYMAP=us\nXKBLAYOUT=us\nXKBMODEL=pc105+inet\nXKBOPTIONS=terminate:ctrl_alt_bksp'

test_step_sets_font() {
    # Today's file names the tiny default font; a fresh one may name none.
    local f pac
    f=$(mktemp)
    printf 'FONT=default8x16\n%s\n' "$KEYMAP_LINES" >"$f"
    pac=$(run_console_step "$f")
    assert_eq "step replaces the default font with Terminus 16x32" "$FONT_LINE" "$(grep '^FONT=' "$f")"
    assert_eq "step keeps the keymap lines" "$KEYMAP_LINES" "$(grep -v '^FONT=' "$f")"
    assert_eq "step installs terminus-font" yes \
        "$(grep -qw terminus-font <<<"$pac" && echo yes || echo no)"
    printf '%s\n' "$KEYMAP_LINES" >"$f"
    run_console_step "$f" >/dev/null
    assert_eq "step adds the font to a file without one" "$FONT_LINE" "$(grep '^FONT=' "$f")"
    assert_eq "step keeps the keymap lines when adding" "$KEYMAP_LINES" "$(grep -v '^FONT=' "$f")"
    rm -f "$f"
}

test_rerun_changes_nothing() {
    # A second bootstrap run must not stack FONT= lines or touch anything.
    local f once twice
    f=$(mktemp)
    printf '%s\n' "$KEYMAP_LINES" >"$f"
    run_console_step "$f" >/dev/null
    once=$(cat "$f")
    run_console_step "$f" 2 >/dev/null
    twice=$(cat "$f")
    assert_eq "file after three runs equals the file after one" "$once" "$twice"
    assert_eq "exactly one FONT= line after three runs" 1 "$(grep -c '^FONT=' "$f")"
    rm -f "$f"
}

MKINITCPIO_CONF="${MKINITCPIO_CONF:-/etc/mkinitcpio.conf}"

test_font_reaches_initramfs() {
    # The font only shows in early boot (and story 13's LUKS prompt) if the
    # initramfs is rebuilt after vconsole.conf names it, with a hook that
    # reads that file.
    local step_line rebuild_line
    step_line=$(grep -n '^step "Console font' "$BOOTSTRAP" | head -1 | cut -d: -f1)
    rebuild_line=$(awk -v from="${step_line:-0}" 'NR > from && /^[[:space:]]*sudo mkinitcpio -P/ {print NR; exit}' "$BOOTSTRAP")
    assert_eq "an initramfs rebuild follows the console font step" yes \
        "$([[ -n $step_line && -n $rebuild_line ]] && echo yes || echo no)"
    assert_eq "live HOOKS read vconsole.conf (consolefont or sd-vconsole)" yes \
        "$(grep -E '^HOOKS=' "$MKINITCPIO_CONF" | grep -qwE 'consolefont|sd-vconsole' && echo yes || echo no)"
}

tests=("$@")
[[ ${#tests[@]} -eq 0 ]] && mapfile -t tests < <(declare -F | awk '{print $3}' | grep '^test_')
for t in "${tests[@]}"; do
    echo "$t"
    "$t"
done
[[ $failures -eq 0 ]] && echo "all passed" || { echo "$failures failed"; exit 1; }
