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

# --- Google Cloud SDK (mac via cask; Linux via brew formula) ---
# macOS cask paths:
if [[ -f /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc ]]; then
  . /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc
  . /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc
elif [[ -f /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc ]]; then
  . /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc
  . /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc
# Linuxbrew formula paths:
elif [[ -f "$(brew --prefix 2>/dev/null)/share/google-cloud-sdk/path.zsh.inc" ]]; then
  . "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  if [[ -f "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc" ]]; then
    . "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
  fi
fi

# --- macOS: prioritize GNU tools for parity with Linux ---
# (safe no-ops on Linux/Intel if dirs don't exist)
if [[ -d /opt/homebrew ]]; then
  path=(
    /opt/homebrew/opt/coreutils/libexec/gnubin
    /opt/homebrew/opt/gnu-sed/libexec/gnubin
    /opt/homebrew/opt/findutils/libexec/gnubin
    $path
  )
elif [[ -d /usr/local/opt/coreutils/libexec/gnubin ]]; then
  path=(
    /usr/local/opt/coreutils/libexec/gnubin
    /usr/local/opt/gnu-sed/libexec/gnubin
    /usr/local/opt/findutils/libexec/gnubin
    $path
  )
fi

# --- Rust (cargo) ---
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Ensure interactive zsh loads ~/.zshrc (covers rare login/WSL edge cases)
if [[ -o interactive ]]; then
  [[ -r "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
fi
