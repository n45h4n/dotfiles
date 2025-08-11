# ----------------------------------------
# Appearance
# ----------------------------------------

# LS/grep colors (fallback if eza not available)
export LS_COLORS='di=1;34:fi=0:ln=1;36:pi=1;33:so=1;35:bd=1;33:cd=1;33:or=1;31:mi=1;31:ex=1;32:*.sh=1;32'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Prefer eza; otherwise colored ls
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias ll='eza -l --icons'
  alias la='eza -la --icons'
  alias lt='eza --tree --icons'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh --color=auto'
  alias la='ls -lAh --color=auto'
fi

# Color man pages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# ----------------------------------------
# Behavior
# ----------------------------------------

# History (bash: HISTCONTROL/shopt equivalents)
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=20000
setopt HIST_IGNORE_DUPS HIST_FIND_NO_DUPS SHARE_HISTORY INC_APPEND_HISTORY
setopt HIST_REDUCE_BLANKS

# Directory/typo helpers
setopt AUTO_CD            # cd on bare dir name
setopt NO_CASE_GLOB       # case-insensitive globbing (bash nocaseglob)
setopt CORRECT            # mild command correction (closest to cdspell)

# Completion
autoload -Uz compinit && compinit
zmodload zsh/complist
# case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# menu selection
zstyle ':completion:*' menu select

# Completion: use zsh's native system (already enabled with compinit above).
# Do not source global bash-completion; it is a bash script and breaks in zsh.
# If you ever need a specific bash completion, opt-in per command only.

# fzf shell integration (installer skipped touching rc)
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"

# ----------------------------------------
# Aliases & Shortcuts
# ----------------------------------------
alias gs='git status'
alias gd='git diff'
alias gu='git pull'
alias ga='git add .'
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
alias reload='source ~/.zshrc'
alias proj='cd $(git rev-parse --show-toplevel 2>/dev/null || echo .)'
alias pidi='cd ~/projects/pidi/pidi-backend'
alias asuri='cd ~/projects/Asuri/'
alias anpr='cd ~/projects/asuri/santos-elizondo/anpr-middleware/'
alias ide='zellij -l dev'
alias cl='clear'
alias venv='source .venv/bin/activate'

# ----------------------------------------
# Prompt (username@host cwd (gitbranch))
# ----------------------------------------
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a)'
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f %F{blue}%~%f${vcs_info_msg_0_} %# '

# ----------------------------------------
# Auto-update: dotfiles repo + Kickstart.nvim
# ----------------------------------------
# - Runs at most once per day (background)
# - Dotfiles: pull --rebase (keeps your local edits)
# - Kickstart.nvim: pull --ff-only (no local edits expected)

typeset -g ZSHRC_PATH="${(%):-%N}"
typeset -g DOTFILES_DIR="${ZSHRC_PATH:A:h:h}"

# remotes (switch to git@... if you prefer SSH)
typeset -g DOTFILES_REMOTE="https://github.com/n45h4n/dotfiles.git"
typeset -g NVIM_REMOTE="https://github.com/n45h4n/kickstart.nvim.git"

typeset -g NVIM_DIR="$HOME/.config/nvim"
typeset -g CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-auto-update"
mkdir -p "$CACHE_DIR"

typeset -g DOTFILES_STAMP="$CACHE_DIR/dotfiles.last"
typeset -g NVIM_STAMP="$CACHE_DIR/nvim.last"
typeset -g ONE_DAY=86400

# portable "mtime" (Linux stat -c, macOS stat -f)
_stat_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }

_should_run_now() {
  local stamp="$1"
  [[ ! -f "$stamp" ]] && return 0
  local now=$(date +%s) last=$(_stat_mtime "$stamp")
  (( now - last >= ONE_DAY ))
}

_git_has_upstream() {
  git -C "$1" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1
}

_set_upstream_to_origin_head() {
  local dir="$1"
  local head_ref
  head_ref=$(git -C "$dir" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null) || return 1
  # head_ref like "origin/main" → branch "main"
  local branch="${head_ref#origin/}"
  git -C "$dir" branch --quiet --set-upstream-to "origin/$branch" >/dev/null 2>&1
}

_git_fetch_ahead() {
  local dir="$1"
  command -v git >/dev/null 2>&1 || return 1
  git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  git -C "$dir" fetch --quiet origin || return 1
  _git_has_upstream "$dir" || _set_upstream_to_origin_head "$dir" || return 1
  local local_head remote_head
  local_head=$(git -C "$dir" rev-parse @)
  remote_head=$(git -C "$dir" rev-parse @{u} 2>/dev/null) || return 1
  [[ "$local_head" != "$remote_head" ]]
}

_auto_update_dotfiles() {
  [[ -d "$DOTFILES_DIR/.git" ]] || return 0
  if _git_fetch_ahead "$DOTFILES_DIR"; then
    # rebase so local tweaks stay on top; autostash handles dirty worktrees
    git -C "$DOTFILES_DIR" pull --rebase --autostash --quiet \
      && print -P "%F{cyan}⬆ dotfiles updated — restart shell to pick up any new files%f"
  fi
  : > "$DOTFILES_STAMP"
}

_auto_update_nvim() {
  if [[ ! -d "$NVIM_DIR/.git" ]]; then
    mkdir -p "${NVIM_DIR:h}"
    git clone --quiet "$NVIM_REMOTE" "$NVIM_DIR" \
      && print -P "%F{cyan}⬇ kickstart.nvim installed%f"
  else
    if _git_fetch_ahead "$NVIM_DIR"; then
      # ff-only to avoid surprises in plugin config
      git -C "$NVIM_DIR" pull --ff-only --quiet \
        && print -P "%F{cyan}⬆ kickstart.nvim updated%f"
    fi
  fi
  : > "$NVIM_STAMP"
}

# Install/upgrade tools from Brewfiles (common + per-OS)
_bundle_brew() {
  command -v brew >/dev/null 2>&1 || return 0
  local root="${DOTFILES_DIR:-$HOME/dotfiles}"
  local common="$root/brew/Brewfile.common"
  local osfile
  case "$(uname -s)" in
    Darwin) osfile="$root/brew/Brewfile.mac" ;;
    Linux)  osfile="$root/brew/Brewfile.linux" ;;
    *) return 0 ;;
  esac
  [ -f "$common" ] && { print -P "%F{yellow}📦 brew bundle (common)%f"; brew bundle --file="$common" || true; }
  [ -f "$osfile" ] && { print -P "%F{yellow}📦 brew bundle ($(uname -s))%f"; brew bundle --file="$osfile" || true; }
}

# Manual trigger
update_all() {
  print -P "%F{yellow}↻ Updating dotfiles, packages, and Kickstart.nvim...%f"
  _auto_update_dotfiles
  _bundle_brew
  _auto_update_nvim
  print -P "%F{green}✅ All up to date%f"
}
alias update-all=update_all

# Auto run once/day in background
{
  _should_run_now "$DOTFILES_STAMP" && _auto_update_dotfiles
  _should_run_now "$NVIM_STAMP"     && _auto_update_nvim
} &>/dev/null &

# ----------------------------------------
# Welcome Message
# ----------------------------------------
echo -e "\e[1;34mWelcome back, Nas! Today is $(date '+%A, %B %d')\e[0m"

# --- fallback Homebrew env if zprofile didn't run (non-login shells) ---
if ! command -v brew >/dev/null 2>&1; then
  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

