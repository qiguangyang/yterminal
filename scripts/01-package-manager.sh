#!/usr/bin/env bash
# Bring the system package manager up to a usable state.
#
# macOS: installs Homebrew if missing, then `brew update`.
# Linux: refreshes the apt cache so later steps don't each pay for it.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_supported_os

if is_macos; then
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
  exit 0
fi

if is_linux; then
  log "Refreshing apt package index"
  apt_update_once
  ok "apt cache refreshed"
  exit 0
fi
