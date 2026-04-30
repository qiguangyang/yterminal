#!/usr/bin/env bash
# Install the Claude Code CLI.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

log "Installing Claude Code CLI"
if have claude; then
  ok "claude already installed at $(command -v claude) ($(claude --version 2>/dev/null || echo unknown))"
  exit 0
fi

curl -fsSL https://claude.ai/install.sh | bash

if [[ -x "$HOME/.local/bin/claude" ]]; then
  ok "Claude installed at $HOME/.local/bin/claude"
  warn "Make sure \$HOME/.local/bin is on your PATH (the included .zshrc handles this via ~/.local/bin/env)."
else
  err "Claude install did not produce ~/.local/bin/claude — check installer output."
  exit 1
fi
