SHELL := /bin/bash

.PHONY: setup setup-macos setup-ubuntu setup-arch setup-common setup-shell setup-nvim test-arch

setup:
./scripts/bootstrap.sh

setup-macos:
DOTFILES_OS_OVERRIDE=macos ./scripts/install_macos.sh

setup-ubuntu:
DOTFILES_OS_OVERRIDE=ubuntu ./scripts/install_ubuntu.sh

setup-arch:
DOTFILES_OS_OVERRIDE=arch ./scripts/install_arch.sh

setup-common:
./scripts/install_common.sh

setup-shell: setup-common

setup-nvim: setup-common

test-arch:
./scripts/test-arch.sh
