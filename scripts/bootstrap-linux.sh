#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (…/dotfiles) regardless of where this script is called from
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "➡️  Bootstrapping Linux/WSL from $DIR"

# 0) Install Homebrew on Linux if missing
if ! command -v brew >/dev/null 2>&1; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	grep -qs 'brew shellenv' "$HOME/.profile" || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME/.profile"
	grep -qs 'brew shellenv' "$HOME/.zprofile" || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
	grep -qs 'brew shellenv' "$HOME/.zshrc" || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME/.zshrc"
fi

# 1) PATH for current session
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# 2) Build deps + gcc (brew recommends)
if command -v apt-get >/dev/null 2>&1; then
	sudo apt-get update -y
	sudo apt-get install -y build-essential
fi
brew install gcc git stow >/dev/null || true

# 3) Ensure vendored forks (submodules) are present
echo "🔁 Initializing submodules (OMZ + Kickstart)…"
if [ -d "$DIR/.git" ]; then
	git -C "$DIR" submodule sync --recursive
	git -C "$DIR" submodule update --init --recursive
fi

# 4) Ensure OMZ custom dir exists in your repo (used by $ZSH_CUSTOM)
mkdir -p "$DIR/omz-custom/plugins" "$DIR/omz-custom/themes"

# 5) Ensure brew’s zsh is an allowed login shell (idempotent)
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [ -x "$BREW_ZSH" ]; then
	grep -qx "$BREW_ZSH" /etc/shells || echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
fi

# 6) Install packages from your Brewfiles
[ -f "$DIR/brew/Brewfile.common" ] && brew bundle --file="$DIR/brew/Brewfile.common" >/dev/null || true
[ -f "$DIR/brew/Brewfile.linux" ] && brew bundle --file="$DIR/brew/Brewfile.linux" >/dev/null || true

# 7) Make brew zsh default (robust)
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 2>/dev/null || true)"
[ -z "${CURRENT_SHELL:-}" ] && CURRENT_SHELL="$(grep "^$USER:" /etc/passwd | cut -d: -f7 || true)"
if [ -x "$BREW_ZSH" ] && [ "$CURRENT_SHELL" != "$BREW_ZSH" ]; then
	chsh -s "$BREW_ZSH" "$USER" || sudo chsh -s "$BREW_ZSH" "$USER" || true
fi

# 7b) Safety net: if bash starts interactively, hop into zsh
if ! grep -qs 'exec zsh -l' "$HOME/.bashrc"; then
	cat >>"$HOME/.bashrc" <<'EOF'
# If an interactive bash shell starts, immediately hop into zsh
case $- in *i*) command -v zsh >/dev/null 2>&1 && exec zsh -l ;; esac
EOF
fi

# Helpers for safe backups before linking
timestamp() { date +%Y%m%d-%H%M%S; }
backup_if_real() {
	local target="$1"
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		local ts
		ts="$(timestamp)"
		mkdir -p "$HOME/.dotfiles-backup/$ts"
		mv -v "$target" "$HOME/.dotfiles-backup/$ts/$(basename "$target")"
	fi
}

# 8) Backup clashing files so stow/symlinks can link cleanly
backup_if_real "$HOME/.zshrc"
backup_if_real "$HOME/.zprofile"
backup_if_real "$HOME/.config/nvim"
backup_if_real "$HOME/.config/zellij"

# 9) Stow your dotfiles (adjust package list as needed)
(cd "$DIR" && stow -v zsh 2>/dev/null || true)
(cd "$DIR" && stow -v git 2>/dev/null || true)

# 10) Neovim: point to your vendored Kickstart fork (no cloning)
mkdir -p "$HOME/.config"
ln -snf "$DIR/vendor/kickstart.nvim" "$HOME/.config/nvim"

# 11) Zellij config (if you keep one in the repo)
[ -d "$DIR/config/zellij" ] && ln -snf "$DIR/config/zellij" "$HOME/.config/zellij"

# 11.5) Oh My Zsh: use your vendored fork
if [ -d "$DIR/vendor/ohmyzsh" ]; then
	ln -snf "$DIR/vendor/ohmyzsh" "$HOME/.oh-my-zsh"
fi

# 12) Post-bundle extras (optional script)
[ -x "$DIR/scripts/post-bundle-common.sh" ] && "$DIR/scripts/post-bundle-common.sh" || true

echo "✅ Linux/WSL bootstrap complete."
# Helpful for WSL users:
if grep -qi microsoft /proc/version 2>/dev/null; then
	echo "👉 In PowerShell, you can run:  wsl --shutdown"
fi
