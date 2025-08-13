# ---------- Shell safety / arrays ----------
typeset -U path PATH fpath

# ---------- Editors ----------
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Locale ----------
export LANG="en_US.UTF-8"

# ---------- Colors / pager ----------
export COLORTERM="truecolor"
export LESS='-R'
# Set TERM only if not set and not under tmux
if [[ -z "${TERM:-}" && -z "${TMUX:-}" ]]; then
  export TERM="xterm-256color"
fi

# ---------- Homebrew (portable: Linuxbrew → Apple Silicon → Intel) ----------
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ---------- PATH (pipx, common bins; keep personal bins first) ----------
path=(
  $HOME/.local/bin
  /usr/local/bin
  $path
)

# ---------- Prefer GNU tools on macOS if installed ----------
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

# ---------- Google Cloud SDK (cask first, then brew prefix if available) ----------
if [[ -f /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc ]]; then
  . /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc
  . /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc
elif [[ -f /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc ]]; then
  . /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc
  . /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc
elif command -v brew >/dev/null 2>&1; then
  GCP_PREFIX="$(brew --prefix 2>/dev/null)"
  if [[ -n "$GCP_PREFIX" && -f "$GCP_PREFIX/share/google-cloud-sdk/path.zsh.inc" ]]; then
    . "$GCP_PREFIX/share/google-cloud-sdk/path.zsh.inc"
    [[ -f "$GCP_PREFIX/share/google-cloud-sdk/completion.zsh.inc" ]] && \
      . "$GCP_PREFIX/share/google-cloud-sdk/completion.zsh.inc"
  fi
fi

# ---------- Rust (cargo) ----------
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# ---------- Do NOT source .zshrc here ----------
# zsh will source ~/.zshrc automatically for interactive shells.
# If you ever need a fallback, do it in a guard in ~/.zshrc itself.

