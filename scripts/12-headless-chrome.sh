#!/usr/bin/env bash
# Install a headless-capable Chrome/Chromium for browser testing
# (Playwright, Puppeteer, Selenium, etc.) and expose it on PATH as `chrome`.
#
# macOS: skipped — most dev Macs already have Chrome.app, and headless test
#   runners pick it up at /Applications/Google\ Chrome.app/.../Google\ Chrome.
# Linux amd64: installs google-chrome-stable from Google's official apt repo.
# Linux arm64: Google doesn't publish Chrome for ARM Linux. Installs apt's
#   `chromium-browser` instead (note: on Ubuntu 24.04 this is a snap-transition
#   package — works on real desktops with snapd, may not work inside minimal
#   containers; falls back gracefully with a clear message).
#
# After install, the binary is symlinked to ~/.local/bin/chrome so all
# downstream tooling can find a stable name.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if is_macos; then
  if [[ -d "/Applications/Google Chrome.app" ]]; then
    ok "Google Chrome.app present at /Applications/Google Chrome.app"
  elif [[ -d "/Applications/Chromium.app" ]]; then
    ok "Chromium.app present at /Applications/Chromium.app"
  else
    warn "No Chrome/Chromium found. Install with: brew install --cask google-chrome"
  fi
  exit 0
fi

linux_only_step

# Headless deps — even if the user later switches to Playwright's bundled
# browser, these system libs are what any chromium binary needs.
log "Installing headless browser system dependencies"
apt_install \
  fonts-liberation \
  libasound2t64 \
  libatk-bridge2.0-0t64 \
  libatk1.0-0t64 \
  libatspi2.0-0t64 \
  libcups2t64 \
  libdbus-1-3 \
  libdrm2 \
  libgbm1 \
  libgtk-3-0t64 \
  libnspr4 \
  libnss3 \
  libwayland-client0 \
  libxcomposite1 \
  libxdamage1 \
  libxfixes3 \
  libxkbcommon0 \
  libxrandr2 \
  xdg-utils

symlink_chrome() {
  local src="$1"
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$src" "$HOME/.local/bin/chrome"
  ok "Symlinked $src -> $HOME/.local/bin/chrome"
}

# Checks that the binary actually launches and prints a version. The Ubuntu
# arm64 chromium-browser package is a snap shim that "installs" successfully
# but errors out at runtime if snapd isn't available (containers).
chrome_binary_works() {
  local bin="$1"
  [[ -x "$bin" ]] && "$bin" --version >/dev/null 2>&1
}

# nvm's PATH setup doesn't carry across step subshells. Source it on demand
# so this step can call npm/npx if it falls back to Playwright's chromium.
ensure_npm_available() {
  if have npm; then return 0; fi
  if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    nvm use default >/dev/null 2>&1 || true
  fi
  have npm
}

install_playwright_chromium() {
  log "Falling back to Playwright's bundled Chromium (works on amd64 + arm64, no snap needed)"
  if ! ensure_npm_available; then
    err "npm not available — cannot install Playwright's chromium."
    err "Install manually later: npx --yes playwright@latest install chromium"
    return 1
  fi
  npx --yes playwright@latest install chromium
  local pw_bin
  pw_bin="$(find "$HOME/.cache/ms-playwright" -type f -name chrome -path '*/chrome-linux/chrome' 2>/dev/null | sort -V | tail -n1)"
  if [[ -z "$pw_bin" ]]; then
    pw_bin="$(find "$HOME/.cache/ms-playwright" -type f -name chrome 2>/dev/null | sort -V | tail -n1)"
  fi
  if chrome_binary_works "$pw_bin"; then
    symlink_chrome "$pw_bin"
    ok "Playwright Chromium ready: $("$pw_bin" --version 2>&1 | head -n1)"
  else
    err "Playwright install completed but no working chromium found under ~/.cache/ms-playwright"
    return 1
  fi
}

install_google_chrome_amd64() {
  if have google-chrome-stable && chrome_binary_works "$(command -v google-chrome-stable)"; then
    ok "google-chrome-stable already installed: $(google-chrome-stable --version)"
    symlink_chrome "$(command -v google-chrome-stable)"
    return 0
  fi
  log "Adding Google Chrome apt repo"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
    | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
  sudo chmod go+r /etc/apt/keyrings/google-chrome.gpg
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
    | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
  unset YTERM_APT_UPDATED
  apt_install google-chrome-stable

  if have google-chrome-stable && chrome_binary_works "$(command -v google-chrome-stable)"; then
    ok "Installed $(google-chrome-stable --version)"
    symlink_chrome "$(command -v google-chrome-stable)"
  else
    err "google-chrome-stable not found / not working after install"
    return 1
  fi
}

install_chromium_arm64() {
  # If a working chromium is already on PATH, use it.
  for candidate in chromium-browser chromium; do
    if have "$candidate" && chrome_binary_works "$(command -v "$candidate")"; then
      ok "$candidate already installed at $(command -v "$candidate")"
      symlink_chrome "$(command -v "$candidate")"
      return 0
    fi
  done

  warn "Google Chrome ships no Linux arm64 build. Trying apt chromium-browser first."
  warn "On Ubuntu 24.04 chromium-browser is a snap transition package — needs snapd."
  apt_install chromium-browser 2>&1 || true

  if have chromium-browser && chrome_binary_works "$(command -v chromium-browser)"; then
    symlink_chrome "$(command -v chromium-browser)"
    return 0
  fi

  warn "apt chromium-browser is the snap shim and snapd isn't functional here."
  install_playwright_chromium
}

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64)  install_google_chrome_amd64 ;;
  arm64)  install_chromium_arm64 ;;
  *)      warn "Architecture $ARCH not supported for headless Chrome — skipping"; exit 0 ;;
esac
