#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
. "$SCRIPT_DIR/os_detect.sh"

case "$(detect_os)" in
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
    printf 'Unsupported OS. Set DOTFILES_OS_OVERRIDE to macos|ubuntu|arch if needed.\n' >&2
    exit 1
    ;;
esac
