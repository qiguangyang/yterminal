#!/usr/bin/env bash
# Shared helpers sourced by install scripts.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

c_reset=$'\033[0m'
c_bold=$'\033[1m'
c_blue=$'\033[34m'
c_green=$'\033[32m'
c_yellow=$'\033[33m'
c_red=$'\033[31m'

log()   { printf '%s==>%s %s%s%s\n' "$c_blue"  "$c_reset" "$c_bold" "$*" "$c_reset"; }
ok()    { printf '%s✓%s %s\n'      "$c_green" "$c_reset" "$*"; }
warn()  { printf '%s!%s %s\n'      "$c_yellow" "$c_reset" "$*"; }
err()   { printf '%s✗%s %s\n'      "$c_red"   "$c_reset" "$*" >&2; }

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    err "This installer targets macOS only."
    exit 1
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

ensure_brew_in_path() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

backup_if_exists() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    local backup="${target}.bak.${stamp}"
    warn "Backing up $target -> $backup"
    mv "$target" "$backup"
  fi
}

link_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    ok "Already linked: $dst"
    return
  fi
  backup_if_exists "$dst"
  ln -s "$src" "$dst"
  ok "Linked $dst -> $src"
}
