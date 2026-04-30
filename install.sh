#!/usr/bin/env bash
# yterminal — bootstrap a macOS dev environment from scratch.
# Runs each script in scripts/ in order. Idempotent — safe to re-run.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

source "$REPO_ROOT/scripts/lib.sh"

steps=(
  "scripts/00-xcode-clt.sh"
  "scripts/01-homebrew.sh"
  "scripts/02-brew-packages.sh"
  "scripts/03-zsh-omz.sh"
  "scripts/04-node-bun.sh"
  "scripts/05-pyenv.sh"
  "scripts/06-claude-code.sh"
  "scripts/07-link-dotfiles.sh"
  "scripts/08-ssh-key.sh"
  "scripts/09-nvim-bootstrap.sh"
  "scripts/10-terminal-profile.sh"
  "scripts/11-gh-auth.sh"
)

if [[ "${1:-}" == "--list" ]]; then
  printf '%s\n' "${steps[@]}"
  exit 0
fi

log "yterminal installer starting from $REPO_ROOT"
for step in "${steps[@]}"; do
  log "── $step ──"
  bash "$REPO_ROOT/$step"
done

ok "All done. Open a new terminal session for everything to take effect."
