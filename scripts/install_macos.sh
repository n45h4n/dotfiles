#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
. "$SCRIPT_DIR/os_detect.sh"
require_os macos

log() {
  printf '\033[1;31m[install-macos]\033[0m %s\n' "$*"
}

ensure_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    return
  fi
  log "Installing Xcode Command Line Tools"
  xcode-select --install || true
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi
  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

configure_brew_shellenv() {
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    printf 'Homebrew not found after installation attempt.\n' >&2
    exit 1
  fi
}

brew_bundle_install() {
  log "Installing Brew bundle packages"
  [ -f "$REPO_ROOT/brew/Brewfile.common" ] && brew bundle --file="$REPO_ROOT/brew/Brewfile.common" --no-upgrade || true
  [ -f "$REPO_ROOT/brew/Brewfile.mac" ] && brew bundle --file="$REPO_ROOT/brew/Brewfile.mac" --no-upgrade || true
}

ensure_docker_desktop() {
  if brew list --cask docker >/dev/null 2>&1; then
    return
  fi
  log "Installing Docker Desktop"
  brew install --cask docker
  if [ -x "/Applications/Docker.app/Contents/MacOS/Docker" ]; then
    log "Launching Docker Desktop in background"
    open -g -a Docker || true
  fi
}

register_brew_zsh() {
  local brew_zsh current
  brew_zsh="$(brew --prefix)/bin/zsh"
  if [ -x "$brew_zsh" ] && ! grep -qx "$brew_zsh" /etc/shells; then
    log "Adding $brew_zsh to /etc/shells"
    echo "$brew_zsh" | sudo tee -a /etc/shells >/dev/null
  fi
  current="$(dscl . -read /Users/"$USER" UserShell 2>/dev/null | awk '{print $2}')"
  if [ -n "$brew_zsh" ] && [ -x "$brew_zsh" ] && [ "${current:-}" != "$brew_zsh" ]; then
    log "Setting default shell to $brew_zsh"
    chsh -s "$brew_zsh" "$USER" || sudo chsh -s "$brew_zsh" "$USER" || true
  fi
}

run_common() {
  "$SCRIPT_DIR/install_common.sh"
}

main() {
  log "Bootstrapping macOS"
  ensure_xcode_clt
  ensure_homebrew
  configure_brew_shellenv
  brew install git stow >/dev/null 2>&1 || true
  brew_bundle_install
  ensure_docker_desktop
  register_brew_zsh
  run_common
  log "macOS bootstrap complete. Restart Terminal/iTerm2."
  log "Docker Compose available via 'docker compose'"
}

main "$@"
