#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (…/dotfiles) regardless of where this script is called from
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 0) Install Homebrew on Linux if missing
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Put brew on PATH for future shells (avoid duplicate lines)
  grep -qs 'brew shellenv' "$HOME/.profile"  || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
  grep -qs 'brew shellenv' "$HOME/.zprofile" || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  grep -qs 'brew shellenv' "$HOME/.zshrc"    || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
fi

# 1) PATH for current session
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# 2) Build deps + gcc (brew recommends)
sudo apt-get update -y
sudo apt-get install -y build-essential
brew install gcc

# 3) Ensure brew’s zsh is an allowed login shell
BREW_ZSH="$(brew --prefix)/bin/zsh"
if ! grep -qx "$BREW_ZSH" /etc/shells; then
  echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
fi

# 4) Install packages (no --no-lock; path from repo root)
brew bundle --file="$DIR/brew/Brewfile.linux"

# 5) Make zsh default (brew version)
chsh -s "$BREW_ZSH" "$USER" || sudo chsh -s "$BREW_ZSH" "$USER" || true

# 6) Symlink dotfiles with stow (run from repo root)
if command -v stow >/dev/null 2>&1; then
  ( cd "$DIR" && stow -v zsh nvim git ) || true
fi

# 7) Neovim config: install or update (your fork)
NVIM_CONFIG="$HOME/.config/nvim"
if [ ! -d "$NVIM_CONFIG/.git" ]; then
  mkdir -p "$HOME/.config"
  # Use HTTPS to avoid requiring SSH keys on fresh machines
  git clone https://github.com/n45h4n/kickstart.nvim.git "$NVIM_CONFIG"
else
  echo "🔄 Updating Kickstart.nvim config..."
  git -C "$NVIM_CONFIG" pull --ff-only || git -C "$NVIM_CONFIG" pull
fi

# 8) Post-bundle extras
"$DIR/scripts/post-bundle-common.sh" || true

echo "✅ Linux/WSL bootstrap complete."
echo "👉 Close all WSL terminals, then in PowerShell run:  wsl --shutdown"
