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

stow_flags=(-v --target="$TARGET" --dir="$DOTFILES_DIR")
[[ "$DRY_RUN" == true ]] && stow_flags+=(--simulate)

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

echo ""
[[ "$DRY_RUN" == true ]] && echo "Dry run complete." || echo "Done."
