#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "➡️  Bootstrapping Linux/WSL from $DIR"

# 0) Install Homebrew on Linux if missing
if ! command -v brew >/dev/null 2>&1; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	grep -qs 'brew shellenv' "$HOME/.profile" || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME/.profile"
	grep -qs 'brew shellenv' "$HOME/.zprofile" || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
fi

# Ensure ZDOTDIR points to $HOME
grep -qs 'export ZDOTDIR=$HOME' "$HOME/.zshenv" || echo 'export ZDOTDIR=$HOME' >>"$HOME/.zshenv"

# 1) PATH for current session
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# 2) Build deps + gcc
if command -v apt-get >/dev/null 2>&1; then
	sudo apt-get update -y
	sudo apt-get install -y build-essential
fi
brew install gcc git stow >/dev/null || true

# 3) Pull submodules
echo "🔁 Initializing submodules (OMZ + Kickstart)…"
if [ -d "$DIR/.git" ]; then
	git -C "$DIR" submodule sync --recursive
	git -C "$DIR" submodule update --init --recursive
fi

# 4) Ensure OMZ custom dir exists
mkdir -p "$DIR/omz-custom/plugins" "$DIR/omz-custom/themes"

# 5) Register brew’s zsh as a valid shell (skip chsh on WSL)
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [ -x "$BREW_ZSH" ] && ! grep -qx "$BREW_ZSH" /etc/shells; then
	echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
fi

# 6) Install packages from Brewfiles
[ -f "$DIR/brew/Brewfile.common" ] && brew bundle --file="$DIR/brew/Brewfile.common" --no-upgrade || true
[ -f "$DIR/brew/Brewfile.linux"  ] && brew bundle --file="$DIR/brew/Brewfile.linux"  --no-upgrade || true

# 6.5) Install google-cloud-cli via apt on WSL/Debian/Ubuntu
if [ -f /etc/os-release ] && grep -qiE 'ubuntu|debian' /etc/os-release; then
	if ! command -v gcloud >/dev/null 2>&1; then
		echo "Installing Google Cloud CLI via apt..."
		sudo apt-get update -y
		sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
		sudo mkdir -p /usr/share/keyrings
		curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
			| sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
		echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
			| sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
		sudo apt-get update -y
		sudo apt-get install -y google-cloud-cli
	fi
fi

# 7) Only try chsh on real Linux
if ! grep -qi microsoft /proc/version 2>/dev/null; then
	CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 2>/dev/null || true)"
	[ -z "${CURRENT_SHELL:-}" ] && CURRENT_SHELL="$(grep "^$USER:" /etc/passwd | cut -d: -f7 || true)"
	if [ -x "$BREW_ZSH" ] && [ "$CURRENT_SHELL" != "$BREW_ZSH" ]; then
		chsh -s "$BREW_ZSH" "$USER" || sudo chsh -s "$BREW_ZSH" "$USER" || true
	fi
fi

# 7b) Safety net: auto-exec zsh from bash
if ! grep -qs 'exec zsh -l' "$HOME/.bashrc"; then
	cat >>"$HOME/.bashrc" <<'EOF'
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

# 8) Backup before stow
backup_if_real "$HOME/.zshrc"
backup_if_real "$HOME/.zprofile"
backup_if_real "$HOME/.config/nvim"
backup_if_real "$HOME/.config/zellij"

# 9) Stow packages
(cd "$DIR" && stow -v zsh) || true
(cd "$DIR" && stow -v git) || true

# 10) Force ~/.zshrc to point to repo
if [ ! -L "$HOME/.zshrc" ] || [ "$(readlink "$HOME/.zshrc" 2>/dev/null)" != "$DIR/zsh/.zshrc" ]; then
	ln -snf "$DIR/zsh/.zshrc" "$HOME/.zshrc"
fi

# 11) Neovim + Zellij configs
mkdir -p "$HOME/.config"
ln -snf "$DIR/vendor/kickstart.nvim" "$HOME/.config/nvim"
[ -d "$DIR/config/zellij" ] && ln -snf "$DIR/config/zellij" "$HOME/.config/zellij"

# 12) Post-bundle extras
[ -x "$DIR/scripts/post-bundle-common.sh" ] && "$DIR/scripts/post-bundle-common.sh" || true

echo "✅ Linux/WSL bootstrap complete."
if grep -qi microsoft /proc/version 2>/dev/null; then
	echo "👉 In PowerShell, you can run:  wsl --shutdown"
fi
