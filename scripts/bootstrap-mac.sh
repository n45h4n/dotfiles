#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (…/dotfiles) regardless of where this script is called from
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 0) Ensure Xcode Command Line Tools (some formulae need them)
if ! xcode-select -p >/dev/null 2>&1; then
  echo "📦 Installing Xcode Command Line Tools (this may pop up a dialog)…"
  xcode-select --install || true
fi

# 1) Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 2) Put brew on PATH for current & future shells
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
grep -qs 'brew shellenv' "$HOME/.zprofile" || {
  if [ -x /opt/homebrew/bin/brew ]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  else
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
  fi
}

# 3) Ensure brew’s zsh is an allowed login shell (idempotent)
BREW_ZSH="$(brew --prefix)/bin/zsh"
grep -qx "$BREW_ZSH" /etc/shells || echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null

# 4) Install packages (from repo root)
brew bundle --file="$DIR/brew/Brewfile.common"
brew bundle --file="$DIR/brew/Brewfile.mac"

# 5) Make zsh default (brew version) — idempotent
CURRENT_SHELL="$(dscl . -read /Users/"$USER" UserShell 2>/dev/null | awk '{print $2}')"
[ "${CURRENT_SHELL:-}" = "$BREW_ZSH" ] || chsh -s "$BREW_ZSH" "$USER" || true

# 5b) Safety net: if bash starts interactively, jump to zsh (harmless on mac)
if ! grep -qs 'exec zsh -l' "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" <<'EOF'
# If an interactive bash shell starts, immediately hop into zsh
case $- in *i*) command -v zsh >/dev/null 2>&1 && exec zsh -l ;; esac
EOF
fi

# 6) Symlink dotfiles with stow (from repo root)
if command -v stow >/dev/null 2>&1; then
  ( cd "$DIR" && stow -v zsh git ) || true
fi

# 7) Neovim config: install or update (your fork)
NVIM_CONFIG="$HOME/.config/nvim"
if [ ! -d "$NVIM_CONFIG/.git" ]; then
  mkdir -p "${NVIM_CONFIG%/*}"
  # Use HTTPS to work on brand‑new machines without SSH keys
  git clone https://github.com/n45h4n/kickstart.nvim.git "$NVIM_CONFIG"
else
  echo "🔄 Updating Kickstart.nvim config..."
  git -C "$NVIM_CONFIG" pull --ff-only || git -C "$NVIM_CONFIG" pull
fi

# 8) Post-bundle extras
"$DIR/scripts/post-bundle-common.sh" || true

echo "✅ mac bootstrap complete. Close & reopen your terminal."
