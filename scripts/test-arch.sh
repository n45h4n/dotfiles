#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

IMAGE="archlinux:latest"
DOCKER_CMD=(
  docker run --rm -t
  -v "$REPO_ROOT:/workspace/dotfiles"
  "$IMAGE"
  /bin/bash -lc
)

TEST_SCRIPT=$(cat <<'EOF'
set -euo pipefail
pacman -Sy --noconfirm git sudo
useradd -m -G wheel -s /bin/bash tester
printf '%%wheel ALL=(ALL) NOPASSWD: ALL\n' >>/etc/sudoers
su - tester -c 'cd /workspace/dotfiles && DOTFILES_OS_OVERRIDE=arch ./scripts/install_arch.sh'
su - tester -c 'zsh --version'
su - tester -c 'nvim --version'
su - tester -c 'python --version'
su - tester -c 'node --version'
su - tester -c 'rustc --version'
su - tester -c 'clang --version'
su - tester -c 'rg --version'
su - tester -c 'fd --version'
su - tester -c "nvim --headless '+checkhealth mason' +qa"
EOF
)

printf 'Running Arch smoke test in Docker (%s)\n' "$IMAGE"
"${DOCKER_CMD[@]}" "$TEST_SCRIPT"
