#!/usr/bin/env bash
# Configure pyenv: install the latest stable CPython release and pin it as the
# global default. The brew formula was installed in step 02; this step does the
# Python install + version pin.
#
# Note: the included .zshrc already exports PYENV_ROOT and runs `pyenv init -`,
# so no shell-rc edits are needed here.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_brew_in_path

if ! have pyenv; then
  err "pyenv not found. Run scripts/02-brew-packages.sh first."
  exit 1
fi

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

ok "pyenv $(pyenv --version | awk '{print $2}')"

# Pick the latest non-prerelease CPython that pyenv knows about.
latest_python="$(pyenv install --list | awk '{$1=$1};1' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -n1)"

if [[ -z "$latest_python" ]]; then
  err "Could not determine the latest Python version from pyenv."
  exit 1
fi

log "Latest stable Python available via pyenv: $latest_python"

if pyenv versions --bare | grep -qx "$latest_python"; then
  ok "Python $latest_python already installed"
else
  log "Installing Python $latest_python (this can take a few minutes)"
  pyenv install "$latest_python"
fi

current_global="$(pyenv global 2>/dev/null || echo none)"
if [[ "$current_global" != "$latest_python" ]]; then
  log "Setting pyenv global to $latest_python (was: $current_global)"
  pyenv global "$latest_python"
else
  ok "pyenv global is already $latest_python"
fi

pyenv rehash
ok "python $(pyenv exec python --version) at $(pyenv which python)"
