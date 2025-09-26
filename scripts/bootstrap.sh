#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

linux_bootstrap() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    local fingerprint
    fingerprint="$(printf '%s %s' "${ID:-}" "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
    if [[ "$fingerprint" == *arch* ]]; then
      exec "$SCRIPT_DIR/install_arch.sh"
    fi
  fi
  exec "$SCRIPT_DIR/install_ubuntu.sh"
}

if [ -n "${DOTFILES_OS_OVERRIDE:-}" ]; then
  case "$DOTFILES_OS_OVERRIDE" in
    macos)
      exec "$SCRIPT_DIR/install_macos.sh"
      ;;
    ubuntu)
      exec "$SCRIPT_DIR/install_ubuntu.sh"
      ;;
    arch)
      exec "$SCRIPT_DIR/install_arch.sh"
      ;;
    *)
      printf 'Unsupported OS override: %s\n' "$DOTFILES_OS_OVERRIDE" >&2
      exit 1
      ;;
  esac
fi

case "$(uname -s)" in
  Darwin)
    exec "$SCRIPT_DIR/install_macos.sh"
    ;;
  Linux)
    linux_bootstrap
    ;;
  *)
    printf 'Unsupported OS. Set DOTFILES_OS_OVERRIDE to macos|ubuntu|arch if needed.\n' >&2
    exit 1
    ;;
esac
