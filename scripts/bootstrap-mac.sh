#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (…/dotfiles) regardless of where this script is called from
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "➡️  Bootstrapping macOS from $DIR"

# 0) Ensure Xcode Command Line Tools (some formulae need them)
if ! xcode-select -p >/dev/null 2>&1; then
	echo "📦 Installing Xcode Command Line Tools (dialog may appear)…"
	xcode-select --install || true
fi

# 1) Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
	echo "🍺 Installing Homebrew…"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 2) Put brew on PATH for current & future shells
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

# Persist brew shellenv
grep -qs 'brew shellenv' "$HOME/.zprofile" || {
	if [ -x /opt/homebrew/bin/brew ]; then
		echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
	else
		echo 'eval "$(/usr/local/bin/brew shellenv)"' >>"$HOME/.zprofile"
	fi
}

# 3) Make sure git + stow exist
brew install git stow >/dev/null || true

# 4) Pull submodules (your OMZ + Kickstart forks live inside the repo)
echo "🔁 Initializing submodules…"
git -C "$DIR" submodule update --init --recursive

# 5) Ensure $ZSH_CUSTOM exists (your repo-tracked custom OMZ dir)
mkdir -p "$DIR/omz-custom/plugins" "$DIR/omz-custom/themes"

# 6) Backup clashing files so stow/symlinks can replace cleanly
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
backup_if_real "$HOME/.zshrc"
backup_if_real "$HOME/.zprofile"
backup_if_real "$HOME/.config/nvim"
backup_if_real "$HOME/.config/zellij"

# 7) Brew installs (from repo Brewfiles)
[ -f "$DIR/brew/Brewfile.common" ] && brew bundle --file="$DIR/brew/Brewfile.common" || true
[ -f "$DIR/brew/Brewfile.mac" ] && brew bundle --file="$DIR/brew/Brewfile.mac" || true

# 8) Stow your packages (adjust to what you keep in the repo)
(cd "$DIR" && stow -v zsh git) || true

# 9) Neovim: symlink to your vendored Kickstart fork
mkdir -p "$HOME/.config"
ln -snf "$DIR/vendor/kickstart.nvim" "$HOME/.config/nvim"

# 10) Zellij (if you keep a config)
[ -d "$DIR/config/zellij" ] && ln -snf "$DIR/config/zellij" "$HOME/.config/zellij"

# 11) Use Homebrew zsh if available; whitelist and set as default
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [ -x "$BREW_ZSH" ]; then
	grep -qx "$BREW_ZSH" /etc/shells || echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
	CURRENT_SHELL="$(dscl . -read /Users/"$USER" UserShell 2>/dev/null | awk '{print $2}')"
	if [ "${CURRENT_SHELL:-}" != "$BREW_ZSH" ]; then
		chsh -s "$BREW_ZSH" "$USER" || sudo chsh -s "$BREW_ZSH" "$USER" || true
	fi
fi

# 12) Post-bundle script (optional)
[ -x "$DIR/scripts/post-bundle-common.sh" ] && "$DIR/scripts/post-bundle-common.sh" || true

# 13) Final restow (fix any files re-created by tools)
(cd "$DIR" && stow -v zsh) || true

echo "✅ mac bootstrap complete. Open a new terminal."
