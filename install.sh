#!/usr/bin/env bash
# yterminal — bootstrap a dev environment from scratch on macOS or Ubuntu/Debian.
# Runs each script in scripts/ in order. Idempotent — safe to re-run.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

source "$REPO_ROOT/scripts/lib.sh"
require_supported_os

steps=(
  "scripts/00-system-deps.sh"
  "scripts/01-package-manager.sh"
  "scripts/02-base-packages.sh"
  "scripts/03-zsh-omz.sh"
  "scripts/04-node-bun.sh"
  "scripts/05-pyenv.sh"
  "scripts/06-coding-clis.sh"
  "scripts/07-link-dotfiles.sh"
  "scripts/08-ssh-key.sh"
  "scripts/09-nvim-bootstrap.sh"
  "scripts/10-terminal-profile.sh"
  "scripts/11-gh-auth.sh"
  "scripts/12-headless-chrome.sh"
)

if [[ "${1:-}" == "--list" ]]; then
  printf '%s\n' "${steps[@]}"
  exit 0
fi

log "yterminal installer starting from $REPO_ROOT (os: $YTERM_OS)"
for step in "${steps[@]}"; do
  log "── $step ──"
  bash "$REPO_ROOT/$step"
done

ok "All done."

# Hand off to zsh so the user lands in the new shell with all dotfiles loaded
# immediately — no need to manually open a new terminal. Skip in non-interactive
# runs (CI, docker exec without -it) so the script stays scriptable.
if have zsh && [[ -t 0 && -t 1 ]]; then
  log "Launching zsh — exit (Ctrl+D) to return to your previous shell."
  exec zsh -l
else
  ok "Open a new terminal session (or run \`zsh -l\`) for everything to take effect."
fi
