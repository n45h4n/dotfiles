# Prompt: green arrow if last command succeeded, red if failed
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$fg[cyan]%}%c%{$reset_color%}"
# Add Git branch + Git status symbols
PROMPT+=' $(git_prompt_info)$(git_prompt_status)'

# Git prompt settings
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "

# Clean/dirty branch
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"

# --- Custom Git status symbols ---
# Ahead of remote → need to push
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg_bold[green]%}↑%{$reset_color%}"
# Behind remote → need to pull
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg_bold[red]%}↓%{$reset_color%}"
# Diverged from remote
ZSH_THEME_GIT_PROMPT_DIVERGED="%{$fg_bold[yellow]%}⇕%{$reset_color%}"
# Modified files
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}✎"
# Untracked files
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[magenta]%}?"
# Staged files
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[cyan]%}+"

