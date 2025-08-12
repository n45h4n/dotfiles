#!/usr/bin/env bash
set -euo pipefail

# Detect Homebrew prefix if available
BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"

# -------------------------
# fzf keybindings + completion (no shell rc edits)
# -------------------------
if [ -n "${BREW_PREFIX:-}" ] && [ -x "$BREW_PREFIX/opt/fzf/install" ]; then
  "$BREW_PREFIX/opt/fzf/install" \
    --key-bindings \
    --completion \
    --no-update-rc \
    --no-bash \
    --no-fish \
    >/dev/null || true
fi

# -------------------------
# pipx + Python CLI tools
# -------------------------
ensure_pipx() {
  if command -v pipx >/dev/null 2>&1; then
    return 0
  fi
  # Try Homebrew first (macOS and Linuxbrew)
  if [ -n "${BREW_PREFIX:-}" ]; then
    brew install pipx >/dev/null 2>&1 || true
    command -v pipx >/dev/null 2>&1 && return 0
  fi
  # Fallback: user install
  python3 -m pip install --user pipx >/dev/null 2>&1 || true
  # Ensure ~/.local/bin is on PATH for this session (common on Linux)
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
}

ensure_pipx
if command -v pipx >/dev/null 2>&1; then
  pipx ensurepath >/dev/null 2>&1 || true
  for pkg in ruff black pre-commit httpie; do
    # install if missing; if installed, try to upgrade quietly
    pipx install "$pkg" >/dev/null 2>&1 || pipx upgrade "$pkg" >/dev/null 2>&1 || true
  done
fi

# -------------------------
# Git LFS
# -------------------------
if command -v git >/dev/null 2>&1; then
  git lfs install >/dev/null 2>&1 || true
fi

# -------------------------
# Linux/WSL: install ngrok (Ubuntu/Debian via apt + keyring)
# macOS is handled by Brewfile (cask "ngrok")
# -------------------------
if [ -f /etc/os-release ] && grep -qiE 'ubuntu|debian' /etc/os-release 2>/dev/null; then
  if ! command -v ngrok >/dev/null 2>&1; then
    if command -v sudo >/dev/null 2>&1; then
      echo "Installing ngrok via apt…"
      # Ensure tools needed for the keyring step exist
      sudo apt-get update -y >/dev/null 2>&1 || true
      sudo apt-get install -y curl gnupg ca-certificates >/dev/null 2>&1 || true
      # Prepare keyring
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/ngrok.gpg
      echo "deb [signed-by=/etc/apt/keyrings/ngrok.gpg] https://ngrok-agent.s3.amazonaws.com stable main" \
        | sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null
      sudo apt-get update -y >/dev/null 2>&1 || true
      sudo apt-get install -y ngrok >/dev/null 2>&1 || true
    else
      echo "⚠️  Skipping ngrok install (sudo not available). Install manually if needed." >&2
    fi
  fi
fi
