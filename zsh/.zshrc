# =============================
# Oh My Zsh (vendored in dotfiles)
# =============================
export ZSH="$HOME/dotfiles/vendor/ohmyzsh"
export ZSH_CUSTOM="$HOME/dotfiles/omz-custom"

# Keep PATH/fpath unique and allow # comments in interactive shells
typeset -U path PATH fpath
setopt INTERACTIVE_COMMENTS

# =============================
# PATH (prefer your bins, GNU coreutils if available)
# =============================
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
# Apple Silicon Homebrew coreutils
[ -d /opt/homebrew/opt/coreutils/libexec/gnubin ] && export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
# Intel mac / Linuxbrew coreutils
[ -d /usr/local/opt/coreutils/libexec/gnubin ] && export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
[ -d /home/linuxbrew/.linuxbrew/bin ] && export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

# ---- MySQL client (Homebrew keg-only) on PATH ----
# macOS (Apple Silicon)
[ -d /opt/homebrew/opt/mysql-client/bin ] && export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
# macOS (Intel)
[ -d /usr/local/opt/mysql-client/bin ] && export PATH="/usr/local/opt/mysql-client/bin:$PATH"
# Linuxbrew / WSL
[ -d /home/linuxbrew/.linuxbrew/opt/mysql-client/bin ] && export PATH="/home/linuxbrew/.linuxbrew/opt/mysql-client/bin:$PATH"

# Ensure Homebrew in PATH early (works on macOS + Linuxbrew)
if ! command -v brew >/dev/null 2>&1; then
  for B in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    [ -x "$B" ] && eval "$("$B" shellenv)" && break
  done
fi

# =============================
# WSL fixes: prefer Linux tools, drop Windows npm path
# =============================
if grep -qi microsoft /proc/version 2>/dev/null; then
  # Put standard Linux bins first
  export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

  # Remove Windows npm dir so we don't hit /mnt/c/.../npm/ngrok
  export PATH="$(echo "$PATH" | tr ':' '\n' \
    | grep -viE '^/mnt/c/Users/[^/]+/AppData/Roaming/npm/?$' \
    | paste -sd: -)"

  # Be explicit about ngrok in WSL if installed
  [ -x /usr/local/bin/ngrok ] && alias ngrok='/usr/local/bin/ngrok'
  [ -x /usr/bin/ngrok ] && alias ngrok='/usr/bin/ngrok'
fi

# =============================
# Oh My Zsh basic settings
# =============================
ZSH_THEME="robbyrussell"
plugins=(git z fzf)

# ---- Completion preferences (must be set BEFORE OMZ compinit) ----
zmodload zsh/complist
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-choices true   # show matches in a list

# Load OMZ (this runs compinit)
source "$ZSH/oh-my-zsh.sh"

# =============================
# Helpers / detection
# =============================
_is_gnu() { "$1" --version 2>/dev/null | head -n1 | grep -qi 'gnu'; }

# =============================
# Colors for pager (man pages)
# =============================
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# =============================
# History & behavior
# =============================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=20000
setopt HIST_IGNORE_DUPS HIST_FIND_NO_DUPS SHARE_HISTORY INC_APPEND_HISTORY
setopt HIST_REDUCE_BLANKS
setopt AUTO_CD       # cd on bare dir name
setopt NO_CASE_GLOB  # case-insensitive globbing

# =============================
# fzf (brew installer set up the files; source them if present)
# =============================
if command -v brew >/dev/null 2>&1; then
  FZF_SHELL="$(brew --prefix)/opt/fzf/shell"
  [ -f "$FZF_SHELL/completion.zsh" ]   && source "$FZF_SHELL/completion.zsh"
  [ -f "$FZF_SHELL/key-bindings.zsh" ] && source "$FZF_SHELL/key-bindings.zsh"
fi
# (tab keybinding left to defaults so menu-select works as expected)

# =============================
# Grep / diff color
# =============================
if _is_gnu grep; then
  alias grep='grep --color=auto'
fi
if command -v gdiff >/dev/null 2>&1 || _is_gnu diff; then
  if command -v gdiff >/dev/null 2>&1; then
    alias diff='gdiff --color=auto'
  else
    alias diff='diff --color=auto'
  fi
fi

# =============================
# ls / eza (override OMZ aliases cleanly)
# =============================
unalias ls 2>/dev/null; unalias ll 2>/dev/null; unalias la 2>/dev/null
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias ll='eza -l --icons'
  alias la='eza -la --icons'
  alias lt='eza --tree --icons'
  compdef _ls eza ls ll la lt
else
  if _is_gnu ls; then
    alias ls='ls --color=auto'
    alias ll='ls -lh --color=auto'
    alias la='ls -lAh --color=auto'
  else
    alias ls='ls -G'
    alias ll='ls -lhG'
    alias la='ls -lAhG'
  fi
fi

# =============================
# Editor & locale
# =============================
export EDITOR="nvim"
export LANG="en_US.UTF-8"

# =============================
# Aliases & shortcuts (yours)
# =============================
alias gs='git status'
alias gd='git diff'
alias gu='git pull'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias mcd='make compose-down'
alias mcu='make compose-up'
alias mn='make ngrok'
alias msql='make mysql'
alias ..='cd ..'
alias ...='cd ~'
alias p='cd ~/projects'
alias v='nvim'
alias rn='ranger'
alias zshrc='nvim ~/.zshrc'
alias ohmyzsh='cd ~/dotfiles/vendor/ohmyzsh/'
alias reload='exec zsh -l'
alias proj='cd $(git rev-parse --show-toplevel 2>/dev/null || echo .)'
alias pidi='cd ~/projects/pidi/pidi-backend'
alias dotfiles='cd ~/dotfiles'
alias kickstart='cd ~/dotfiles/vendor/kickstart.nvim'
alias asuri='cd ~/projects/Asuri/'
alias ide='zellij -l ide'
alias cl='clear'
alias venv='source .venv/bin/activate'

# =============================
# Prompt
# =============================
# Using OMZ theme (robbyrussell above). For vcs_info prompt, uncomment below.
# autoload -Uz vcs_info
# precmd() { vcs_info }
# zstyle ':vcs_info:git:*' formats ' (%b)'
# zstyle ':vcs_info:git:*' actionformats ' (%b|%a)'
# setopt PROMPT_SUBST
# PROMPT='%F{green}%n@%m%f %F{blue}%~%f${vcs_info_msg_0_} %# '

# =============================
# Simple updater (safe with submodules)
# =============================
update-all() {
  echo "↻ Updating dotfiles & submodules…"
  ( cd "$HOME/dotfiles" \
    && git pull --rebase --autostash --quiet || true \
    && git submodule sync --recursive \
    && git submodule update --init --recursive )
  if command -v brew >/dev/null 2>&1; then
    [ -f "$HOME/dotfiles/brew/Brewfile.common" ] && brew bundle --file="$HOME/dotfiles/brew/Brewfile.common" >/dev/null || true
    case "$(uname -s)" in
      Darwin) [ -f "$HOME/dotfiles/brew/Brewfile.mac" ]   && brew bundle --file="$HOME/dotfiles/brew/Brewfile.mac"   >/dev/null || true ;;
      Linux)  [ -f "$HOME/dotfiles/brew/Brewfile.linux" ] && brew bundle --file="$HOME/dotfiles/brew/Brewfile.linux" >/dev/null || true ;;
    esac
  fi
  echo "✅ All up to date"
}

# =============================
# Fallback Homebrew env if zprofile didn't run (non-login shells)
# =============================
if ! command -v brew >/dev/null 2>&1; then
  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

