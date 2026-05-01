#!/usr/bin/env bash
# Headlessly bootstrap Neovim plugins via lazy.nvim so first launch is instant.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_brew_in_path

# On Linux, step 02 installs nvim under ~/.local/bin — make sure that's on PATH
# for this script's own lookup.
export PATH="$HOME/.local/bin:$PATH"

if ! have nvim; then
  err "nvim not found — run scripts/02-base-packages.sh first."
  exit 1
fi

log "Syncing lazy.nvim plugins (headless)"
nvim --headless "+Lazy! sync" +qa || warn "Lazy sync exited non-zero — retry interactively with :Lazy sync if needed"

log "Installing TreeSitter parsers"
nvim --headless "+TSUpdateSync" +qa || true

ok "Neovim bootstrap complete"
