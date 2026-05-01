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

have() { command -v "$1" >/dev/null 2>&1; }

# OS detection ───────────────────────────────────────────────────────────────
# YTERM_OS is one of: macos, linux, unsupported.
# Linux means a Debian/Ubuntu-family distro with apt-get available.
detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)
      if [[ -r /etc/os-release ]]; then
        local id id_like
        id="$(. /etc/os-release && echo "${ID:-}")"
        id_like="$(. /etc/os-release && echo "${ID_LIKE:-}")"
        case "$id" in
          ubuntu|debian|pop|linuxmint|elementary|raspbian|kali) echo linux ;;
          *)
            case "$id_like" in
              *debian*|*ubuntu*) echo linux ;;
              *) echo unsupported ;;
            esac
            ;;
        esac
      else
        echo unsupported
      fi
      ;;
    *) echo unsupported ;;
  esac
}

YTERM_OS="${YTERM_OS:-$(detect_os)}"
export YTERM_OS

is_macos() { [[ "$YTERM_OS" == "macos" ]]; }
is_linux() { [[ "$YTERM_OS" == "linux" ]]; }

require_supported_os() {
  case "$YTERM_OS" in
    macos|linux) ;;
    *)
      err "Unsupported OS: $(uname -srm)"
      err "yterminal supports macOS and Debian/Ubuntu-family Linux."
      exit 1
      ;;
  esac
}

require_macos() {
  if ! is_macos; then
    err "This step requires macOS (current: $YTERM_OS)"
    exit 1
  fi
}

# Soft skip — for steps that exist only on macOS but should not abort the
# rest of the pipeline when run on Linux.
mac_only_step() {
  if ! is_macos; then
    warn "Skipping — $(basename "${BASH_SOURCE[1]:-step}") is macOS-only (current: $YTERM_OS)"
    exit 0
  fi
}

linux_only_step() {
  if ! is_linux; then
    warn "Skipping — $(basename "${BASH_SOURCE[1]:-step}") is Linux-only (current: $YTERM_OS)"
    exit 0
  fi
}

ensure_brew_in_path() {
  is_macos || return 0
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# Interactive prompt with timeout ───────────────────────────────────────────
# prompt_with_timeout PROMPT DEFAULT [TIMEOUT_SEC]
#
# Print PROMPT to /dev/tty, wait up to TIMEOUT_SEC for the user, and echo
# their response on stdout. If the user presses Enter without typing OR the
# timeout fires, echo DEFAULT instead. The default timeout (30s) can be
# overridden globally via YTERM_PROMPT_TIMEOUT.
#
# Designed to be captured: ans="$(prompt_with_timeout "  choice" "1")"
# All UI noise (the prompt, the timeout banner) goes to /dev/tty so it never
# pollutes the captured value.
prompt_with_timeout() {
  local prompt="$1"
  local default="$2"
  local timeout="${3:-${YTERM_PROMPT_TIMEOUT:-30}}"

  # No tty (e.g. CI driver, `docker exec` without -it, piped stdin) — return
  # the default immediately so the pipeline keeps moving. The device node
  # /dev/tty exists in containers even when it can't be opened, so probe it
  # for real instead of stat-ing.
  if ! { : <>/dev/tty; } 2>/dev/null; then
    printf '%s' "$default"
    return 0
  fi

  printf '%s [%ds, default=%s]: ' "$prompt" "$timeout" "$default" >/dev/tty

  local answer=""
  if read -r -t "$timeout" answer </dev/tty; then
    [[ -z "$answer" ]] && answer="$default"
  else
    # read returns >128 on timeout / EOF
    printf '\n  (no input within %ds — using default: %q)\n' "$timeout" "$default" >/dev/tty
    answer="$default"
  fi
  printf '%s' "$answer"
}

# apt helpers ────────────────────────────────────────────────────────────────
apt_update_once() {
  is_linux || return 0
  if [[ -z "${YTERM_APT_UPDATED:-}" ]]; then
    log "Refreshing apt cache (sudo apt-get update)"
    sudo apt-get update -y
    export YTERM_APT_UPDATED=1
  fi
}

# apt_install pkg1 pkg2 ...
# Skips packages already installed; runs apt_update_once on demand.
apt_install() {
  is_linux || return 0
  local missing=()
  for pkg in "$@"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      ok "$pkg already installed"
    else
      missing+=("$pkg")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    apt_update_once
    log "apt-get install -y ${missing[*]}"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
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
