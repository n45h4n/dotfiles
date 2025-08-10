#!/usr/bin/env bash
set -euo pipefail

# 0) Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 1) Put brew on PATH for current & future shells
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
if ! grep -qs 'brew shellenv' "$HOME/.zprofile"; then
  { echo 'eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"'; } >> "$HOME/.zprofile"
fi

# 2) Ensure brew’s zsh is an allowed login shell
BREW_ZSH="$(brew --prefix)/bin/zsh"
if ! grep -qx "$BREW_ZSH" /etc/shells; then
  echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
fi

# 3) Install packages
brew bundle --file="$(dirname "$0")/brew/Brewfile.mac" --no-lock

# 4) Make zsh default (brew version)
chsh -s "$BREW_ZSH" "$USER" || true

# 5) Symlink dotfiles if present
if command -v stow >/dev/null 2>&1; then
  ( cd "$(dirname "$0")" && stow -v zsh nvim git 2>/dev/null || true )
fi

# 6) Neovim config: clone if missing (your fork)
if [ ! -d "$HOME/.config/nvim" ]; then
  mkdir -p "$HOME/.config"
  git clone https://github.com/n45h4n/kickstart.nvim.git "$HOME/.config/nvim"
fi

# 7) Post-bundle extras
"$(dirname "$0")/scripts/post-bundle-common.sh" || true

echo "✅ mac bootstrap complete. Open a new terminal window."

