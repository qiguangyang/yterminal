#!/usr/bin/env bash
# Ensure baseline system tools needed by every later step (compiler toolchain,
# curl, git, ca-certificates).
#
# macOS: triggers the Xcode Command Line Tools install dialog if missing.
# Linux: apt-installs build-essential and friends (sudo password prompt).

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_supported_os

if is_macos; then
  log "Checking Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then
    ok "Xcode CLT present at $(xcode-select -p)"
    exit 0
  fi

  warn "Xcode CLT not found. A GUI dialog will open — accept and wait for it to finish, then re-run this script."
  xcode-select --install || true
  exit 1
fi

if is_linux; then
  log "Installing baseline build + network tools via apt"
  apt_install \
    build-essential \
    curl \
    wget \
    git \
    ca-certificates \
    file \
    unzip \
    gnupg \
    lsb-release \
    software-properties-common
  ok "Baseline system deps installed"
  exit 0
fi
