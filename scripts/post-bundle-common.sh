#!/usr/bin/env bash
set -euo pipefail

# Run once after brew bundle to wire up extras (fzf keybindings, global CLIs, LSPs, Git LFS). Both platforms can use this.

# fzf keybindings + completion (no shell rc edits)
if [ -x "$(brew --prefix)/opt/fzf/install" ]; then
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

# Python CLIs
pipx ensurepath || true
for pkg in ruff black pre-commit httpie; do
  pipx install "$pkg" >/dev/null 2>&1 || true
done

# Node LSPs for Neovim
if command -v npm >/dev/null 2>&1; then
  npm install -g typescript typescript-language-server pyright >/dev/null 2>&1 || true
fi

# Git LFS
if command -v git >/dev/null 2>&1; then
  git lfs install || true
fi

