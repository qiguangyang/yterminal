#!/usr/bin/env bash
# Authenticate the GitHub CLI. The `gh` binary itself is installed in step 02.
# This step runs `gh auth login` interactively so the user can sign in via
# browser/device flow. Skipped if already authenticated.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_brew_in_path

if ! have gh; then
  err "gh not found. Run scripts/02-brew-packages.sh first."
  exit 1
fi

ok "gh installed: $(gh --version | head -n1)"

if gh auth status >/dev/null 2>&1; then
  ok "gh already authenticated"
  gh auth status 2>&1 | sed 's/^/  /'
  exit 0
fi

log "Launching interactive GitHub login (gh auth login)"
warn "Choose: GitHub.com → SSH → use existing ~/.ssh/id_ed25519 → login via browser"

# Pre-select reasonable defaults but still let the user step through the flow.
# --git-protocol ssh ties git remotes to the SSH key just generated in step 08.
gh auth login --hostname github.com --git-protocol ssh --web

if gh auth status >/dev/null 2>&1; then
  ok "gh authenticated successfully"
else
  warn "gh auth did not complete — re-run: gh auth login"
fi
