#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
. "$SCRIPT_DIR/os_detect.sh"
require_os arch

PACKAGES=()

log() {
  printf '\033[1;35m[install-arch]\033[0m %s\n' "$*"
}

ensure_pacman_update() {
  log "Updating system packages via pacman"
  sudo pacman -Syu --noconfirm
}

read_packages() {
  local pkg_file line
  pkg_file="$REPO_ROOT/packages/arch.txt"
  if [ ! -r "$pkg_file" ]; then
    printf 'Package manifest not found: %s\n' "$pkg_file" >&2
    exit 1
  fi
  PACKAGES=()
  while IFS= read -r line; do
    case "$line" in
      ''|'#'*) continue ;;
    esac
    PACKAGES+=("$line")
  done <"$pkg_file"
}

install_packages() {
  if [ "${#PACKAGES[@]}" -eq 0 ]; then
    return
  fi
  log "Installing core packages via pacman"
  sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
}

configure_rustup() {
  if command -v rustup >/dev/null 2>&1; then
    log "Ensuring rustup default toolchain is stable"
    rustup default stable >/dev/null 2>&1 || rustup toolchain install stable >/dev/null 2>&1 || true
  fi
}

install_aur_extras() {
  local helper=""
  if command -v paru >/dev/null 2>&1; then
    helper="paru"
  elif command -v yay >/dev/null 2>&1; then
    helper="yay"
  fi
  if [ -z "$helper" ]; then
    log "Skipping AUR packages (paru/yay not found)"
    return
  fi
  log "Installing AUR packages (google-cloud-cli, ngrok) via $helper"
  "$helper" -S --needed --noconfirm google-cloud-cli ngrok || true
}

ensure_login_shell() {
  local target current
  target="/usr/bin/zsh"
  if [ ! -x "$target" ]; then
    return
  fi
  current="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || true)"
  if [ -z "$current" ]; then
    current="$(grep "^$USER:" /etc/passwd | cut -d: -f7 || true)"
  fi
  if [ "$current" = "$target" ]; then
    return
  fi
  log "Setting default shell to $target"
  chsh -s "$target" "$USER" || sudo chsh -s "$target" "$USER" || true
}

run_common() {
  "$SCRIPT_DIR/install_common.sh"
}

main() {
  ensure_pacman_update
  read_packages
  install_packages
  configure_rustup
  install_aur_extras
  ensure_login_shell
  run_common
  log "Arch bootstrap complete. Open a new shell to use zsh."
}

main "$@"
