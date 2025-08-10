#!/usr/bin/env bash
set -euo pipefail

# Shell fzf bindings (optional but nice)
if [ -x "$(brew --prefix)/opt/fzf/install" ]; then
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

# Optional: Python CLIs for use outside Neovim
pipx ensurepath || true
for pkg in ruff black pre-commit httpie; do
  pipx install "$pkg" >/dev/null 2>&1 || true
done

# No global npm LSPs — Mason in Kickstart handles these inside Neovim
# if command -v npm >/dev/null 2>&1; then
#   npm install -g typescript typescript-language-server pyright >/dev/null 2>&1 || true
# fi

# Git LFS (optional but harmless)
if command -v git >/dev/null 2>&1; then
  git lfs install || true
fi

