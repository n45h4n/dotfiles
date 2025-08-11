#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (…/dotfiles) regardless of where this script is called from
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 0) Install Homebrew on Linux if missing
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

# 3) Ensure brew’s zsh is an allowed login shell (idempotent)
BREW_ZSH="$(brew --prefix)/bin/zsh"
grep -qx "$BREW_ZSH" /etc/shells || echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null

# 4) Install packages (from repo root)
brew bundle --file="$DIR/brew/Brewfile.common"
brew bundle --file="$DIR/brew/Brewfile.linux"

# 5) Make zsh default (brew version) — idempotent + robust
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 2>/dev/null || true)"
if [ -z "${CURRENT_SHELL:-}" ]; then
  CURRENT_SHELL="$(grep "^$USER:" /etc/passwd | cut -d: -f7 || true)"
fi
if [ "$CURRENT_SHELL" != "$BREW_ZSH" ]; then
  chsh -s "$BREW_ZSH" "$USER" || sudo chsh -s "$BREW_ZSH" "$USER" || true
fi

# 5b) Safety net: if bash starts interactively, jump to zsh
if ! grep -qs 'exec zsh -l' "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" <<'EOF'
# If an interactive bash shell starts, immediately hop into zsh
case $- in *i*) command -v zsh >/dev/null 2>&1 && exec zsh -l ;; esac
EOF
fi

# 6) Symlink dotfiles with stow (run from repo root)

# Backup clashing files so stow can link cleanly
for f in "$HOME/.zshrc" "$HOME/.zprofile"; do
  if [ -e "$f" ] && [ ! -L "$f" ]; then
    ts=$(date +%Y%m%d-%H%M%S)
    mkdir -p "$HOME/.dotfiles-backup/$ts"
    mv -v "$f" "$HOME/.dotfiles-backup/$ts/$(basename "$f")"
  fi
done

if command -v stow >/dev/null 2>&1; then
  ( cd "$DIR" && stow -v zsh git ) || true
fi

# 7) Neovim config: install or update (your fork)
NVIM_CONFIG="$HOME/.config/nvim"
if [ ! -d "$NVIM_CONFIG/.git" ]; then
  mkdir -p "$HOME/.config"
  git clone https://github.com/n45h4n/kickstart.nvim.git "$NVIM_CONFIG"
else
  echo "🔄 Updating Kickstart.nvim config..."
  git -C "$NVIM_CONFIG" pull --ff-only || git -C "$NVIM_CONFIG" pull
fi

# 8) Post-bundle extras
"$DIR/scripts/post-bundle-common.sh" || true

echo "✅ Linux/WSL bootstrap complete."
echo "👉 In PowerShell, run:  wsl --shutdown"
