#!/usr/bin/env bash
set -euo pipefail

log() { printf "\033[1;36m[post-bundle]\033[0m %s\n" "$*"; }

# Detect Homebrew prefix if available
BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"

# -------------------------
# fzf keybindings + completion (no shell rc edits)
# -------------------------
if [ -n "${BREW_PREFIX:-}" ] && [ -x "$BREW_PREFIX/opt/fzf/install" ]; then
	# The installer is idempotent with --no-update-rc; still log once
	log "Ensuring fzf keybindings & completion"
	"$BREW_PREFIX/opt/fzf/install" \
		--key-bindings \
		--completion \
		--no-update-rc \
		--no-bash \
		--no-fish \
		>/dev/null 2>&1 || true
fi

# -------------------------
# pipx + Python CLI tools
# -------------------------
ensure_pipx() {
	if command -v pipx >/dev/null 2>&1; then return 0; fi

	# Prefer Homebrew if present (macOS & Linuxbrew)
	if [ -n "${BREW_PREFIX:-}" ]; then
		log "Installing pipx via Homebrew"
		brew install pipx >/dev/null 2>&1 || true
		command -v pipx >/dev/null 2>&1 && return 0
	fi

	# Fallback: user install
	if command -v python3 >/dev/null 2>&1; then
		log "Installing pipx via python3 --user"
		python3 -m pip install --user pipx >/dev/null 2>&1 || true
	fi

	# Ensure ~/.local/bin is in PATH for this session
	case ":${PATH}:" in
	*":$HOME/.local/bin:"*) ;; # already there
	*) export PATH="$HOME/.local/bin:$PATH" ;;
	esac
}

ensure_pipx
if command -v pipx >/dev/null 2>&1; then
	pipx ensurepath >/dev/null 2>&1 || true
	# Install/upgrade selected tools quietly
	for pkg in ruff black pre-commit httpie; do
		pipx install "$pkg" >/dev/null 2>&1 || pipx upgrade "$pkg" >/dev/null 2>&1 || true
	done
fi

# -------------------------
# Git LFS
# -------------------------
if command -v git >/dev/null 2>&1; then
	# harmless if already installed; avoids noisy output on WSL
	git lfs install --force >/dev/null 2>&1 || true
fi

# -------------------------
# Linux/WSL: ngrok via apt (macOS handled by Brewfile cask)
# -------------------------
if [ -f /etc/os-release ] && grep -qiE 'ubuntu|debian' /etc/os-release 2>/dev/null; then
	if ! command -v ngrok >/dev/null 2>&1; then
		if command -v sudo >/dev/null 2>&1; then
			log "Installing ngrok from official apt repo"
			sudo apt-get update -y >/dev/null 2>&1 || true
			sudo apt-get install -y curl ca-certificates gnupg >/dev/null 2>&1 || true

			# Prepare keyring once
			sudo mkdir -p /etc/apt/keyrings
			if [ ! -f /etc/apt/keyrings/ngrok.gpg ]; then
				curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo gpg --dearmor -o /etc/apt/keyrings/ngrok.gpg
				sudo chmod 0644 /etc/apt/keyrings/ngrok.gpg || true
			fi

			# Add repo (idempotent)
			if [ ! -f /etc/apt/sources.list.d/ngrok.list ]; then
				echo "deb [signed-by=/etc/apt/keyrings/ngrok.gpg] https://ngrok-agent.s3.amazonaws.com stable main" |
					sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null
			fi

			sudo apt-get update -y >/dev/null 2>&1 || true
			sudo apt-get install -y ngrok >/dev/null 2>&1 || true
		else
			echo "⚠️  Skipping ngrok install (sudo not available)." >&2
		fi
	fi
fi
