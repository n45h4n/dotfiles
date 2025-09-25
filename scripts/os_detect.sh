#!/usr/bin/env bash
set -euo pipefail

_detect_from_release() {
  if [ ! -r /etc/os-release ]; then
    return 1
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  local id_like id
  id="${ID:-}"
  id_like="${ID_LIKE:-}"
  local fingerprint
  fingerprint="$(printf '%s %s' "$id" "$id_like" | tr '[:upper:]' '[:lower:]')"
  case "$fingerprint" in
    *arch*)
      printf 'arch\n'
      return 0
      ;;
    *ubuntu*|*debian*)
      printf 'ubuntu\n'
      return 0
      ;;
  esac
  return 1
}

detect_os() {
  if [ -n "${DOTFILES_OS_OVERRIDE:-}" ]; then
    printf '%s\n' "$DOTFILES_OS_OVERRIDE"
    return 0
  fi

  case "$(uname -s)" in
    Darwin)
      printf 'macos\n'
      return 0
      ;;
    Linux)
      if _detect_from_release; then
        return 0
      fi
      ;;
  esac
  printf 'unknown\n'
}

require_os() {
  local expected actual
  expected="$1"
  actual="$(detect_os)"
  if [ "$actual" != "$expected" ]; then
    printf 'Unsupported or unexpected OS: expected %s, detected %s\n' "$expected" "$actual" >&2
    exit 1
  fi
}
