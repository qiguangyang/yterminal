#!/usr/bin/env bash
# Ensure Xcode Command Line Tools are present.
# Required by Homebrew, git, and most compilers.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_macos

log "Checking Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  ok "Xcode CLT present at $(xcode-select -p)"
  exit 0
fi

warn "Xcode CLT not found. A GUI dialog will open — accept and wait for it to finish, then re-run this script."
xcode-select --install || true
exit 1
