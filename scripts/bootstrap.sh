#!/usr/bin/env bash
set -euo pipefail
case "$(uname -s)" in
  Darwin) exec "$(dirname "$0")/bootstrap-mac.sh" ;;
  Linux)  exec "$(dirname "$0")/bootstrap-linux.sh" ;;
  *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac
