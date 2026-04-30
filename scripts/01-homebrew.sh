#!/usr/bin/env bash
# Install Homebrew (the macOS package manager) if it is not already present,
# then update its formula database. Adds brew to the current shell's PATH so
# subsequent steps can call `brew` directly.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_macos

log "Checking Homebrew"
if have brew; then
  ok "brew already installed at $(command -v brew)"
else
  log "Installing Homebrew from https://brew.sh"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

ensure_brew_in_path

if ! have brew; then
  err "brew not on PATH after install — try opening a new shell and re-running."
  exit 1
fi

ok "brew $(brew --version | head -n1)"

log "Updating Homebrew"
brew update
ok "Homebrew is up to date"
