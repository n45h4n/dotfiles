#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
. "$SCRIPT_DIR/os_detect.sh"
require_os ubuntu

log() {
  printf '\033[1;32m[install-ubuntu]\033[0m %s\n' "$*"
}

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

ensure_linuxbrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi
  log "Installing Homebrew/Linuxbrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    grep -qs 'brew shellenv' "$HOME/.profile" || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME/.profile"
    grep -qs 'brew shellenv' "$HOME/.zprofile" || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
  fi
}

configure_brew_shellenv() {
  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  BREW_PREFIX="$(brew --prefix)"
}

install_build_tools() {
  if command -v apt-get >/dev/null 2>&1; then
    log "Installing build-essential via apt"
    sudo apt-get update -y
    sudo apt-get install -y build-essential
  fi
  brew install gcc git stow >/dev/null 2>&1 || true
}

brew_bundle_install() {
  log "Installing Brew bundle packages"
  [ -f "$REPO_ROOT/brew/Brewfile.common" ] && brew bundle --file="$REPO_ROOT/brew/Brewfile.common" --no-upgrade || true
  [ -f "$REPO_ROOT/brew/Brewfile.linux" ] && brew bundle --file="$REPO_ROOT/brew/Brewfile.linux" --no-upgrade || true
}

install_google_cloud_cli() {
  if [ ! -f /etc/os-release ]; then
    return
  fi
  if ! grep -qiE 'ubuntu|debian' /etc/os-release; then
    return
  fi
  if command -v gcloud >/dev/null 2>&1; then
    return
  fi
  log "Installing Google Cloud CLI via apt"
  sudo apt-get update -y
  sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
  sudo mkdir -p /usr/share/keyrings
  if [ ! -f /usr/share/keyrings/cloud.google.gpg ]; then
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
  fi
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y google-cloud-cli
}

install_ngrok_and_locale() {
  if [ ! -f /etc/os-release ]; then
    return
  fi
  if ! grep -qiE 'ubuntu|debian' /etc/os-release; then
    return
  fi
  if ! command -v ngrok >/dev/null 2>&1; then
    log "Installing ngrok via apt"
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null
    sudo apt update
    sudo apt install -y ngrok
  fi
  log "Ensuring locale en_US.UTF-8"
  sudo apt install -y locales
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8
}

install_docker() {
  if [ ! -f /etc/os-release ]; then
    return
  fi
  if ! grep -qiE 'ubuntu|debian' /etc/os-release; then
    return
  fi
  if command -v docker >/dev/null 2>&1; then
    return
  fi
  log "Installing Docker Engine and plugins"
  sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  local codename arch
  codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME}")"
  arch="$(dpkg --print-architecture)"
  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu %s stable\n' "$arch" "$codename" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo groupadd -f docker
  sudo usermod -aG docker "$USER"
  log "Docker installed. Compose available via 'docker compose'"
  if is_wsl; then
    enable_wsl_systemd
  fi
}

enable_wsl_systemd() {
  if [ ! -f /etc/wsl.conf ] || ! grep -qs 'systemd=true' /etc/wsl.conf; then
    log "Enabling systemd in /etc/wsl.conf"
    sudo mkdir -p /etc
    { echo '[boot]'; echo 'systemd=true'; } | sudo tee /etc/wsl.conf >/dev/null
    log "Run 'wsl --shutdown' in PowerShell to apply systemd."
  fi
}

register_brew_zsh() {
  if is_wsl; then
    return
  fi
  local brew_zsh
  brew_zsh="$(brew --prefix)/bin/zsh"
  if [ -x "$brew_zsh" ] && ! grep -qx "$brew_zsh" /etc/shells; then
    log "Adding $brew_zsh to /etc/shells"
    echo "$brew_zsh" | sudo tee -a /etc/shells >/dev/null
  fi
  local current
  current="$(getent passwd "$USER" | cut -d: -f7 2>/dev/null || true)"
  if [ -z "$current" ]; then
    current="$(grep "^$USER:" /etc/passwd | cut -d: -f7 || true)"
  fi
  if [ -n "$brew_zsh" ] && [ -x "$brew_zsh" ] && [ "$current" != "$brew_zsh" ]; then
    log "Setting default shell to $brew_zsh"
    chsh -s "$brew_zsh" "$USER" || sudo chsh -s "$brew_zsh" "$USER" || true
  fi
}

ensure_bash_exec_zsh() {
  local target="$HOME/.bashrc"
  if [ ! -f "$target" ]; then
    touch "$target"
  fi
  if ! grep -qs 'exec zsh -l' "$target"; then
    log "Adding zsh auto-launch to .bashrc"
    cat >>"$target" <<'EOF'
case $- in *i*) command -v zsh >/dev/null 2>&1 && exec zsh -l ;; esac
EOF
  fi
}

enforce_login_shell_exec() {
  local file tmp
  for file in "$HOME/.bash_profile" "$HOME/.profile"; do
    [ -e "$file" ] || : >"$file"
    if ! grep -qs '/usr/bin/zsh -l' "$file" && ! grep -qs '/home/linuxbrew/.linuxbrew/bin/zsh -l' "$file"; then
      log "Ensuring $file auto-launches zsh"
      tmp="$(mktemp)"
      {
        echo 'if [ -x /usr/bin/zsh ]; then'
        echo '  exec /usr/bin/zsh -l'
        echo 'elif [ -x /home/linuxbrew/.linuxbrew/bin/zsh ]; then'
        echo '  exec /home/linuxbrew/.linuxbrew/bin/zsh -l'
        echo 'fi'
        cat "$file"
      } >"$tmp"
      mv "$tmp" "$file"
    fi
  done
}

run_common() {
  "$SCRIPT_DIR/install_common.sh"
}

main() {
  log "Bootstrapping Ubuntu/WSL"
  ensure_linuxbrew
  configure_brew_shellenv
  install_build_tools
  brew_bundle_install
  install_google_cloud_cli
  install_ngrok_and_locale
  install_docker
  register_brew_zsh
  ensure_bash_exec_zsh
  enforce_login_shell_exec
  run_common
  log "Ubuntu/WSL bootstrap complete"
  if is_wsl; then
    log "Run 'wsl --shutdown' in PowerShell, then reopen Ubuntu."
    log "After restart, run 'newgrp docker' or open a new terminal for docker access."
  fi
}

main "$@"
