#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export DOTFILES_DIR="${REPO_ROOT}"

log() {
  printf '\033[1;34m[install-common]\033[0m %s\n' "$*"
}

ensure_real_file() {
  local target
  target="$1"
  if [ -L "$target" ]; then
    rm -f "$target"
  fi
  mkdir -p "$(dirname "$target")"
  touch "$target"
}

append_guarded_block() {
  local target marker content
  target="$1"
  marker="$2"
  content="$3"
  ensure_real_file "$target"
  if grep -Fq "# >>> $marker >>>" "$target"; then
    return
  fi
  {
    printf '\n# >>> %s >>>\n' "$marker"
    printf '%s\n' "$content"
    printf '# <<< %s <<<\n' "$marker"
  } >>"$target"
}

sync_submodules() {
  if [ -d "$REPO_ROOT/.git" ] && command -v git >/dev/null 2>&1; then
    log "Syncing git submodules"
    git -C "$REPO_ROOT" submodule sync --recursive
    git -C "$REPO_ROOT" submodule update --init --recursive
  fi
}

ensure_omz_dirs() {
  mkdir -p "$REPO_ROOT/omz-custom/plugins" "$REPO_ROOT/omz-custom/themes"
}

configure_zshenv() {
  local content
  content="export ZDOTDIR=\"$HOME\""
  append_guarded_block "$HOME/.zshenv" "dotfiles-zshenv" "$content"
}

configure_zprofile() {
  local content
# Keep $DOTFILES_DIR literal so the user's shell expands it later.
  content=$(cat <<'EOF'
export DOTFILES_DIR="__DOTFILES_DIR__"
if [ -f "$DOTFILES_DIR/zsh/.zprofile" ]; then
  . "$DOTFILES_DIR/zsh/.zprofile"
fi
EOF
)
  content=${content/__DOTFILES_DIR__/${REPO_ROOT}}
  append_guarded_block "$HOME/.zprofile" "dotfiles-zprofile" "$content"
}

configure_zshrc() {
  local content
# Keep $DOTFILES_DIR literal so the user's shell expands it later.
  content=$(cat <<'EOF'
export DOTFILES_DIR="__DOTFILES_DIR__"
if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
  . "$DOTFILES_DIR/zsh/.zshrc"
fi
EOF
)
  content=${content/__DOTFILES_DIR__/${REPO_ROOT}}
  append_guarded_block "$HOME/.zshrc" "dotfiles-zshrc" "$content"
}

stow_git_config() {
  if command -v stow >/dev/null 2>&1; then
    (cd "$REPO_ROOT" && stow --target "$HOME" git) || true
    return
  fi
  if ! command -v git >/dev/null 2>&1; then
    return
  fi
  if git config --global --get-all include.path | grep -Fx "$REPO_ROOT/git/.gitconfig" >/dev/null 2>&1; then
    return
  fi
  git config --global --add include.path "$REPO_ROOT/git/.gitconfig"
}

ensure_nvim_bridge() {
  local nvim_dir init_file tmp content
  nvim_dir="$HOME/.config/nvim"
  init_file="$nvim_dir/init.lua"
  if [ -L "$nvim_dir" ] && [ "$(readlink "$nvim_dir")" = "$REPO_ROOT/vendor/kickstart.nvim" ]; then
    rm -f "$nvim_dir"
  fi
  mkdir -p "$nvim_dir"
  content=$(cat <<'LUA'
-- Managed by dotfiles installer
local dotfiles_dir = os.getenv('DOTFILES_DIR') or os.getenv('HOME') .. '/dotfiles'
local kickstart = dotfiles_dir .. '/vendor/kickstart.nvim/init.lua'
local stat = vim.loop.fs_stat(kickstart)
if stat then
  dofile(kickstart)
else
  vim.notify('Kickstart.nvim not found at ' .. kickstart, vim.log.levels.ERROR)
end
LUA
)
  tmp="$(mktemp)"
  printf '%s\n' "$content" >"$tmp"
  if [ ! -f "$init_file" ] || ! cmp -s "$tmp" "$init_file"; then
    mv "$tmp" "$init_file"
  else
    rm -f "$tmp"
  fi
}

ensure_ssh_permissions() {
  if [ -d "$HOME/.ssh" ]; then
    chmod 700 "$HOME/.ssh" || true
    [ -f "$HOME/.ssh/config" ] && chmod 600 "$HOME/.ssh/config" || true
    find "$HOME/.ssh" -maxdepth 1 -type f -name 'id_*' -exec chmod 600 {} + 2>/dev/null || true
  fi
}

run_post_bundle() {
  local script
  script="$REPO_ROOT/scripts/post-bundle-common.sh"
  if [ -x "$script" ]; then
    "$script"
  fi
}

main() {
  sync_submodules
  ensure_omz_dirs
  configure_zshenv
  configure_zprofile
  configure_zshrc
  stow_git_config
  ensure_nvim_bridge
  ensure_ssh_permissions
  run_post_bundle
  log "Common install complete"
}

main "$@"
