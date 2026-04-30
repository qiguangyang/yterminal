#!/usr/bin/env bash
# Install nvm + latest stable Node, Bun, and pnpm.
# `nvm install node` resolves to the most recent stable release (the Current
# line, not necessarily LTS) and we pin it as the default so new shells use it.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_brew_in_path

log "Installing nvm"
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

log "Installing latest stable Node via nvm"
nvm install node
nvm alias default node
nvm use default >/dev/null
ok "node $(node --version), npm $(npm --version)"

log "Installing Bun"
if ! have bun; then
  curl -fsSL https://bun.sh/install | bash
fi
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
have bun && ok "bun $(bun --version)"

log "Installing pnpm"
if ! have pnpm; then
  curl -fsSL https://get.pnpm.io/install.sh | sh -
fi
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
have pnpm && ok "pnpm $(pnpm --version)"
