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

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    log "This installer must be run as root. Try re-running with sudo."
    exit 1
  fi
}

TARGET_USER=""
TARGET_HOME=""

initialize_target_context() {
  TARGET_USER="${SUDO_USER:-$USER}"
  TARGET_HOME="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6 || true)"
  if [ -z "$TARGET_HOME" ]; then
    TARGET_HOME="$(awk -F: -v user="$TARGET_USER" '$1 == user {print $6}' /etc/passwd 2>/dev/null || true)"
  fi
  if [ -z "$TARGET_HOME" ]; then
    TARGET_HOME="$HOME"
  fi
}

run_as_target_user() {
  if [ -z "$TARGET_USER" ]; then
    initialize_target_context
  fi
  if [ "$TARGET_USER" = "$(id -un)" ]; then
    env HOME="$TARGET_HOME" "$@"
    return
  fi
  if command -v sudo >/dev/null 2>&1; then
    sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" "$@"
  else
    runuser -u "$TARGET_USER" -- env HOME="$TARGET_HOME" "$@"
  fi
}

ensure_pacman_update() {
  log "Updating system packages via pacman"
  pacman -Syu --noconfirm
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
  pacman -S --needed --noconfirm "${PACKAGES[@]}"
}

# Ensure Docker packages, service, and group membership are configured idempotently.
ensure_docker_stack() {
  local -a docker_packages missing
  if [ -z "$TARGET_USER" ]; then
    initialize_target_context
  fi
  docker_packages=(docker docker-buildx docker-compose)
  missing=()

  for pkg in "${docker_packages[@]}"; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    log "Installing Docker packages: ${missing[*]}"
    pacman -S --needed --noconfirm "${missing[@]}"
  else
    log "Docker packages already installed"
  fi

  if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-enabled docker >/dev/null 2>&1; then
      log "docker service already enabled"
    else
      log "Enabling docker service"
      systemctl enable docker >/dev/null 2>&1 || log "Failed to enable docker service; continuing"
    fi
    if systemctl is-active docker >/dev/null 2>&1; then
      log "docker service already running"
    else
      log "Starting docker service"
      systemctl start docker >/dev/null 2>&1 || log "Failed to start docker service; continuing"
    fi
  else
    log "systemctl not available; skipping docker service enablement"
  fi

  local docker_user group_list
  docker_user="$TARGET_USER"

  if getent group docker >/dev/null 2>&1; then
    log "docker group already exists"
  else
    log "Creating docker group"
    groupadd docker
  fi

  if getent passwd "$docker_user" >/dev/null 2>&1; then
    group_list="$(id -nG "$docker_user" 2>/dev/null || true)"
    if printf '%s\n' "$group_list" | tr ' ' '\n' | grep -qx 'docker'; then
      log "User $docker_user already in docker group"
    else
      log "Adding user $docker_user to docker group"
      if usermod -aG docker "$docker_user"; then
        printf '>>> %s was added to the '\''docker'\'' group. Log out/in (or reboot) to apply.\n' "$docker_user"
      else
        log "Failed to add user $docker_user to docker group; continuing"
      fi
    fi
  else
    log "User $docker_user not found; skipping docker group membership"
  fi

  if command -v docker >/dev/null 2>&1; then
    log "docker --version"
    docker --version
  else
    log "docker command not available"
  fi

  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    log "docker compose version"
    docker compose version
  elif command -v docker-compose >/dev/null 2>&1; then
    log "docker-compose --version"
    docker-compose --version
  else
    log "Docker Compose command not available"
  fi
}

configure_rustup() {
  if command -v rustup >/dev/null 2>&1; then
    log "Ensuring rustup default toolchain is stable"
    if ! run_as_target_user rustup default stable >/dev/null 2>&1; then
      run_as_target_user rustup toolchain install stable >/dev/null 2>&1 || true
    fi
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
  run_as_target_user "$helper" -S --needed --noconfirm google-cloud-cli ngrok || true
}

ensure_login_shell() {
  local target current shells_file
  target="/usr/bin/zsh"
  shells_file="/etc/shells"

  if [ ! -x "$target" ]; then
    if [ -e "$target" ]; then
      log "Target shell $target is not executable; skipping login shell change"
    else
      log "Target shell $target not found; skipping login shell change"
    fi
    return
  fi

  if [ -w "$shells_file" ] || [ ! -e "$shells_file" ]; then
    if [ -e "$shells_file" ] && grep -Fxq "$target" "$shells_file"; then
      log "Target shell $target already registered in $shells_file"
    else
      log "Registering $target in $shells_file"
      printf '%s\n' "$target" >>"$shells_file"
    fi
  else
    log "Cannot modify $shells_file; skipping login shell change"
    return
  fi

  if [ -z "$TARGET_USER" ]; then
    initialize_target_context
  fi
  current="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f7 || true)"
  if [ -z "$current" ]; then
    current="$(awk -F: -v user="$TARGET_USER" '$1 == user {print $7}' /etc/passwd 2>/dev/null || true)"
  fi
  if [ "$current" = "$target" ]; then
    return
  fi
  log "Setting default shell for $TARGET_USER to $target"
  chsh -s "$target" "$TARGET_USER" || sudo chsh -s "$target" "$TARGET_USER" || true
}

run_common() {
  run_as_target_user "$SCRIPT_DIR/install_common.sh"
}

main() {
  require_root
  initialize_target_context
  ensure_pacman_update
  read_packages
  install_packages
  ensure_docker_stack
  configure_rustup
  install_aur_extras
  ensure_login_shell
  run_common
  log "Arch bootstrap complete. Open a new shell to use zsh."
}

main "$@"
