# --- PATH & editors ---
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"  # pipx + common bin
export EDITOR="nvim"
export VISUAL="nvim"

# --- Locale & terminal colors ---
export LANG="en_US.UTF-8"
export TERM="xterm-256color"
export COLORTERM="truecolor"
export LESS='-R'

# --- Homebrew (portable) ---
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# --- Rust (cargo) ---
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Ensure interactive zsh loads ~/.zshrc (covers WSL/login edge cases)
if [[ -o interactive ]]; then
  [[ -r "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
fi
