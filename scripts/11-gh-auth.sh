#!/usr/bin/env bash
# Authenticate the GitHub CLI. The `gh` binary itself is installed in step 02.
# This step runs `gh auth login` interactively so the user can sign in via
# browser/device flow. Skipped if already authenticated, or if the environment
# is clearly headless (container/server with no browser opener).

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_brew_in_path

if ! have gh; then
  err "gh not found. Run scripts/02-base-packages.sh first."
  exit 1
fi

ok "gh installed: $(gh --version | head -n1)"

if gh auth status >/dev/null 2>&1; then
  ok "gh already authenticated"
  gh auth status 2>&1 | sed 's/^/  /'
  exit 0
fi

# Detect environments where the OAuth browser flow can't complete locally.
# gh's --web flag tries: xdg-open, x-www-browser, www-browser, wslview (Linux)
# or `open` (macOS). If none are available, the device-code flow still works
# but requires the user to copy a URL onto a different device, which isn't
# what someone running install.sh in a Docker container or over plain SSH is
# generally set up to do. Skip with a clear hint instead of stalling at a
# half-broken prompt.
has_browser_opener() {
  if is_macos; then
    have open && return 0
  fi
  have xdg-open || have x-www-browser || have www-browser || have wslview
}

if ! has_browser_opener; then
  warn "No browser opener detected — looks like a headless environment (container, SSH session, or server)."
  warn "Skipping gh auth. Authenticate later from a machine with a browser:"
  warn "  gh auth login --hostname github.com --git-protocol ssh --web"
  warn "Or paste a personal access token now with:"
  warn "  gh auth login --hostname github.com --git-protocol ssh --with-token < token.txt"
  exit 0
fi

# Default to skip — the OAuth flow takes the user out of the terminal into a
# browser and can stall the install if they're not ready. Type "y" within the
# 30s timeout to opt in; otherwise we skip and tell them how to authenticate
# later. This makes the installer safe to walk away from on macOS, where the
# browser opener IS available and would otherwise stall waiting for input.
auth_choice="$(prompt_with_timeout "  Sign in to GitHub now? [y/skip]" "skip")"
if [[ ! "$auth_choice" =~ ^[Yy] ]]; then
  warn "Skipping GitHub auth. Authenticate later with:"
  warn "  gh auth login --hostname github.com --git-protocol ssh --web"
  exit 0
fi

log "Launching interactive GitHub login (gh auth login)"
warn "Choose: GitHub.com → SSH → use existing ~/.ssh/id_ed25519 → login via browser"

# --git-protocol ssh ties git remotes to the SSH key generated in step 08.
gh auth login --hostname github.com --git-protocol ssh --web

if gh auth status >/dev/null 2>&1; then
  ok "gh authenticated successfully"
else
  warn "gh auth did not complete — re-run: gh auth login"
fi
