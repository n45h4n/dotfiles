#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (…/dotfiles) regardless of where this script is called from
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "➡️  Bootstrapping macOS from $DIR"

# 0) Ensure Xcode Command Line Tools (some formulae need them)
if ! xcode-select -p >/dev/null 2>&1; then
	echo "📦 Installing Xcode Command Line Tools (a dialog may appear)…"
	xcode-select --install || true
fi

# 1) Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
	echo "🍺 Installing Homebrew…"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 2) Put brew on PATH for this session
if [ -x /opt/homebrew/bin/brew ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
	BREW_PREFIX="/opt/homebrew"
elif [ -x /usr/local/bin/brew ]; then
	eval "$(/usr/local/bin/brew shellenv)"
	BREW_PREFIX="/usr/local"
else
	echo "❌ Homebrew not found after install attempt."
	exit 1
fi

# (We DO NOT append to ~/.zprofile here; your repo's zsh/.zprofile will be stowed later)

# 3) Make sure git + stow exist
brew install git stow >/dev/null || true

# 4) Pull submodules (your OMZ + Kickstart live inside the repo)
echo "🔁 Initializing submodules…"
if [ -d "$DIR/.git" ]; then
	git -C "$DIR" submodule sync --recursive
	git -C "$DIR" submodule update --init --recursive
fi

# 5) Ensure $ZSH_CUSTOM exists (your repo-tracked custom OMZ dir)
mkdir -p "$DIR/omz-custom/plugins" "$DIR/omz-custom/themes"

# Helpers
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

# 6) Backup clashing files so stow/symlinks can replace cleanly
backup_if_real "$HOME/.zshrc"
backup_if_real "$HOME/.zprofile"
backup_if_real "$HOME/.config/nvim"
backup_if_real "$HOME/.config/zellij"

# 7) Brew installs (from repo Brewfiles)
[ -f "$DIR/brew/Brewfile.common" ] && brew bundle --file="$DIR/brew/Brewfile.common" >/dev/null || true
[ -f "$DIR/brew/Brewfile.mac" ] && brew bundle --file="$DIR/brew/Brewfile.mac" >/dev/null || true

# 8) Stow your packages (adjust to what you keep in the repo)
#    This will create ~/.zshrc -> ~/dotfiles/zsh/.zshrc and ~/.zprofile -> ~/dotfiles/zsh/.zprofile
(cd "$DIR" && stow -v zsh) || true
(cd "$DIR" && stow -v git) || true

# 9) Neovim: symlink to your vendored Kickstart fork
mkdir -p "$HOME/.config"
ln -snf "$DIR/vendor/kickstart.nvim" "$HOME/.config/nvim"

# 10) Zellij (if you keep a config)
[ -d "$DIR/config/zellij" ] && ln -snf "$DIR/config/zellij" "$HOME/.config/zellij"

# 10.5) (REMOVED) Oh My Zsh symlink to ~/.oh-my-zsh — not needed anymore
# Your .zshrc uses $HOME/dotfiles/vendor/ohmyzsh directly.

# 11) Ensure ~/.zshrc points to repo file (in case stow was skipped)
if [ ! -L "$HOME/.zshrc" ] || [ "$(readlink "$HOME/.zshrc" 2>/dev/null || true)" != "$DIR/zsh/.zshrc" ]; then
	ln -snf "$DIR/zsh/.zshrc" "$HOME/.zshrc"
fi

# 12) Use Homebrew zsh if available; whitelist and set as default
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [ -x "$BREW_ZSH" ]; then
	grep -qx "$BREW_ZSH" /etc/shells || echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
	CURRENT_SHELL="$(dscl . -read /Users/"$USER" UserShell 2>/dev/null | awk '{print $2}')"
	if [ "${CURRENT_SHELL:-}" != "$BREW_ZSH" ]; then
		chsh -s "$BREW_ZSH" "$USER" || sudo chsh -s "$BREW_ZSH" "$USER" || true
	fi
fi

# 13) Post-bundle script (optional)
[ -x "$DIR/scripts/post-bundle-common.sh" ] && "$DIR/scripts/post-bundle-common.sh" || true

# 14) Final restow (fix any files re-created by tools)
(cd "$DIR" && stow -v zsh) || true

echo "✅ mac bootstrap complete. Open a new terminal."
