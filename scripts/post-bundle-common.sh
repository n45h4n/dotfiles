#!/usr/bin/env bash
set -euo pipefail

# fzf keybindings + completion (no shell rc edits)
if [ -x "$(brew --prefix)/opt/fzf/install" ]; then
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

# Python CLIs (isolated via pipx)
pipx ensurepath || true
for pkg in ruff black pre-commit httpie; do
  pipx install "$pkg" >/dev/null 2>&1 || true
done

# Git LFS
if command -v git >/dev/null 2>&1; then
  git lfs install || true
fi

# -------------------------
# Linux/WSL: install ngrok
# -------------------------
# Homebrew has no ngrok *formula* (mac uses a cask). On Ubuntu/WSL install via apt.
if [ -f /etc/os-release ] && grep -qi "ubuntu" /etc/os-release; then
  if ! command -v ngrok >/dev/null 2>&1; then
    echo "Installing ngrok via apt…"
    # Import repo key
    curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
      | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    # Add repo (use 'stable main' channel)
    echo "deb https://ngrok-agent.s3.amazonaws.com stable main" \
      | sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null
    # Install
    sudo apt update -y && sudo apt install -y ngrok || true
  fi
fi

# (macOS handles ngrok via: cask "ngrok" in brew/Brewfile.mac)
