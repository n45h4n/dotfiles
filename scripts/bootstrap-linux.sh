#!/usr/bin/env bash
set -euo pipefail

# 0) Install Homebrew on Linux if missing
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add to shells
  test -r "$HOME/.profile" && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
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

# 4) Install packages
brew bundle --file="$(dirname "$0")/brew/Brewfile.linux" --no-lock

# 5) Make zsh default (brew version)
chsh -s "$BREW_ZSH" "$USER" || sudo chsh -s "$BREW_ZSH" "$USER" || true

# 6) Symlink dotfiles
( cd "$(dirname "$0")" && stow -v zsh nvim git 2>/dev/null || true )

# 7) Neovim config: install or update (your fork)
NVIM_CONFIG="$HOME/.config/nvim"
if [ ! -d "$NVIM_CONFIG" ]; then
  mkdir -p "$HOME/.config"
  git clone git@github.com:n45h4n/kickstart.nvim.git "$NVIM_CONFIG"
else
  echo "🔄 Updating Kickstart.nvim config..."
  git -C "$NVIM_CONFIG" pull
fi

# 8) Post-bundle extras
"$(dirname "$0")/scripts/post-bundle-common.sh" || true

echo "✅ Linux/WSL bootstrap complete. Close & reopen your WSL session."

