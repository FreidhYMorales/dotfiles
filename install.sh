#!/usr/bin/env bash
# install.sh — Entry point for a fresh Arch Linux setup.
#
# Three ways to run:
#
#   From inside the cloned repo:
#     ./install.sh [--no-gpu] [--dir=/custom/path]
#
#   With the repo already on disk at a custom path:
#     DOTFILES_DIR=/path/to/Configuraciones ./install.sh [--no-gpu]
#
#   Without cloning first (piped from curl):
#     curl -fsSL <raw-url>/install.sh | bash
#     curl -fsSL <raw-url>/install.sh | bash -s -- --no-gpu
#     curl -fsSL <raw-url>/install.sh | bash -s -- --no-gpu --dir=/custom/path

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/FreidhYMorales/dotfiles.git"
DEFAULT_CLONE_DIR="$HOME/Mio/Configuraciones"

# ── Flags ────────────────────────────────────────────────────────────────────
NO_GPU=false
CLONE_DIR="${DOTFILES_DIR:-$DEFAULT_CLONE_DIR}"

for arg in "$@"; do
  case "$arg" in
    --no-gpu)  NO_GPU=true ;;
    --dir=*)   CLONE_DIR="${arg#--dir=}" ;;
  esac
done

step() { echo ""; echo "==> $*"; }

# ── Ensure git is available (bootstrap needs it too, but we need it first) ───
if ! command -v git &>/dev/null; then
  step "Installing git"
  sudo pacman -S --needed --noconfirm git
fi

# ── Locate the repo ──────────────────────────────────────────────────────────
# When piped via curl, BASH_SOURCE[0] is empty or /dev/stdin — detect that.
SELF="${BASH_SOURCE[0]:-}"
REPO_ROOT=""

if [[ -n "$SELF" && "$SELF" != "/dev/stdin" && "$SELF" != "bash" ]]; then
  CANDIDATE="$(cd "$(dirname "$SELF")" && pwd)"
  [[ -f "$CANDIDATE/dotfiles/bootstrap.sh" ]] && REPO_ROOT="$CANDIDATE"
fi

if [[ -z "$REPO_ROOT" && -f "$CLONE_DIR/dotfiles/bootstrap.sh" ]]; then
  # Repo already on disk at the expected location (e.g. external disk mounted).
  REPO_ROOT="$CLONE_DIR"
  step "Repo found at $REPO_ROOT — skipping clone"
fi

if [[ -z "$REPO_ROOT" ]]; then
  step "Cloning repo into $CLONE_DIR"
  mkdir -p "$(dirname "$CLONE_DIR")"
  git clone "$REPO_URL" "$CLONE_DIR"
  REPO_ROOT="$CLONE_DIR"
fi

# ── Hand off to bootstrap ────────────────────────────────────────────────────
BOOTSTRAP="$REPO_ROOT/dotfiles/bootstrap.sh"

if [[ ! -f "$BOOTSTRAP" ]]; then
  echo "ERROR: bootstrap.sh not found at $BOOTSTRAP" >&2
  exit 1
fi

step "Handing off to bootstrap.sh (repo: $REPO_ROOT)"

ARGS=()
[[ "$NO_GPU" == true ]] && ARGS+=(--no-gpu)

exec bash "$BOOTSTRAP" "${ARGS[@]}"
