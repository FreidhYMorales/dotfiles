#!/usr/bin/env bash
# Deploy dotfiles using GNU Stow.
# Usage:
#   ./deploy.sh           — stow all packages
#   ./deploy.sh nvim zsh  — stow specific packages only
#   ./deploy.sh --dry-run — simulate without making changes

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME"
DRY_RUN=false

# Packages that are not ready yet (skipped by default)
PENDING=()

args=()
packages=()

for arg in "$@"; do
    if [[ "$arg" == "--dry-run" ]]; then
        DRY_RUN=true
    else
        packages+=("$arg")
    fi
done

# --adopt moves conflicting real files into the stow package so the link can be
# created, then git restore puts back the repo version. Net effect: conflicts are
# resolved non-interactively and the repo copy always wins.
stow_flags=(-v --target="$TARGET" --dir="$DOTFILES_DIR")
[[ "$DRY_RUN" == false ]] && stow_flags+=(--adopt)
[[ "$DRY_RUN" == true ]]  && stow_flags+=(--simulate)

if [[ "${#packages[@]}" -gt 0 ]]; then
    # Deploy specific packages
    for pkg in "${packages[@]}"; do
        echo "  stow $pkg"
        stow "${stow_flags[@]}" "$pkg"
    done
else
    # Deploy all packages, skip pending
    for pkg in "$DOTFILES_DIR"/*/; do
        pkg=$(basename "$pkg")
        if [[ " ${PENDING[*]} " == *" $pkg "* ]]; then
            echo "  skip $pkg (pending)"
            continue
        fi
        echo "  stow $pkg"
        stow "${stow_flags[@]}" "$pkg"
    done
fi

if [[ "$DRY_RUN" != true ]]; then
    # Restore any files --adopt may have pulled in from the system, so the repo
    # version always wins over whatever was on disk before stowing.
    GIT_ROOT="$(git -C "$DOTFILES_DIR" rev-parse --show-toplevel 2>/dev/null)" || true
    if [[ -n "$GIT_ROOT" ]]; then
        git -C "$GIT_ROOT" restore -- dotfiles/ 2>/dev/null || true
    fi
fi

echo ""
[[ "$DRY_RUN" == true ]] && echo "Dry run complete." || echo "Done."
