#!/usr/bin/env bash
# Install nvm + latest stable Node, Bun, and pnpm.
# `nvm install node` resolves to the most recent stable release (the Current
# line, not necessarily LTS) and we pin it as the default so new shells use it.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_brew_in_path

# Bun, pnpm, nvm installers all blindly append PATH/HOME exports to ~/.zshrc
# and ~/.bashrc. If those files are already symlinks into our dotfiles repo
# (after a prior run of step 07), the appends would pollute the source-of-truth
# dotfile with host-specific paths. Detach any such symlinks for the duration
# of this script so the installers scribble on a real local file (which step 07
# later backs up). Re-link on exit so new shells still load our dotfiles.
declare -a YTERM_RC_RELINKS=()

protect_rc_symlink() {
  local rc="$1"
  [[ -L "$rc" ]] || return 0
  local target
  target="$(readlink "$rc")"
  local content
  content="$(cat "$rc" 2>/dev/null || true)"
  rm "$rc"
  printf '%s' "$content" > "$rc"
  YTERM_RC_RELINKS+=("$rc::$target")
}

restore_rc_symlinks() {
  local entry rc target
  # bash 3.2 (default on macOS) errors on "${arr[@]}" when arr is empty under
  # `set -u`. The ${arr[@]+...} idiom yields nothing for empty arrays.
  for entry in ${YTERM_RC_RELINKS[@]+"${YTERM_RC_RELINKS[@]}"}; do
    rc="${entry%%::*}"
    target="${entry##*::}"
    rm -f "$rc"
    ln -s "$target" "$rc"
  done
}
trap restore_rc_symlinks EXIT

protect_rc_symlink "$HOME/.zshrc"
protect_rc_symlink "$HOME/.bashrc"

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
  # pnpm's installer needs $SHELL set to know which rc to touch. In contexts
  # without a login shell (docker exec, CI runners) it's empty, so export a
  # sane default into the environment so the installer (run via `sh -` over
  # a pipe) can see it. The dotfiles manage PNPM_HOME / PATH themselves, so
  # whichever shell the installer picks here is harmless.
  export SHELL="${SHELL:-/bin/bash}"
  curl -fsSL https://get.pnpm.io/install.sh | sh -
fi
# pnpm installer chooses a different default home per OS (mirrored in dotfiles/zshrc).
if is_macos; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
export PATH="$PNPM_HOME:$PATH"
have pnpm && ok "pnpm $(pnpm --version)"
