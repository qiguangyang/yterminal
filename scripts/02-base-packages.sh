#!/usr/bin/env bash
# Install the base CLI toolset (editors, search, fonts, language runtimes deps)
# via the OS's native package manager, plus a few tools that are easier to
# install from upstream installers than from the distro.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_supported_os

# AstroNvim's hard minimum. Used by both macOS and Linux paths.
NVIM_FLOOR="0.10.0"

nvim_version() {
  have nvim || return 1
  nvim --version 2>/dev/null | head -n1 | awk '{print $2}' | sed 's/^v//'
}

# Returns 0 if nvim is on PATH and >= NVIM_FLOOR.
nvim_meets_floor() {
  local v
  v="$(nvim_version)" || return 1
  [[ -n "$v" ]] || return 1
  [[ "$(printf '%s\n%s\n' "$NVIM_FLOOR" "$v" | sort -V | head -n1)" == "$NVIM_FLOOR" ]]
}

# ── macOS via Homebrew ──────────────────────────────────────────────────────

# brew's neovim formula is usually current, but a stale local install can lag
# behind the AstroNvim minimum. Version-check before relying on `brew list`.
install_neovim_brew() {
  if nvim_meets_floor; then
    ok "nvim $(nvim_version) already installed (>= $NVIM_FLOOR)"
    return 0
  fi
  if brew list --formula neovim >/dev/null 2>&1; then
    log "Upgrading brew neovim ($(nvim_version 2>/dev/null || echo missing) < $NVIM_FLOOR)"
    brew upgrade neovim
  else
    log "brew install neovim"
    brew install neovim
  fi
  if nvim_meets_floor; then
    ok "nvim $(nvim_version) installed (>= $NVIM_FLOOR)"
  else
    err "brew neovim is still < $NVIM_FLOOR after install/upgrade — check 'brew doctor'"
    return 1
  fi
}

install_macos() {
  ensure_brew_in_path

  # neovim handled separately so we can floor-check it
  local formulae=(
    ripgrep
    bat
    gh
    wget
    pyenv
    uv
    tree-sitter
    coreutils
    ffmpeg
    sqlite
    openssl@3
    readline
    xz
    zsh
  )
  local casks=(
    font-hack-nerd-font   # patched font with icons for nvim/terminal
  )

  log "Installing brew formulae: ${formulae[*]}"
  for f in "${formulae[@]}"; do
    if brew list --formula "$f" >/dev/null 2>&1; then
      ok "$f already installed"
    else
      log "brew install $f"
      brew install "$f"
    fi
  done

  install_neovim_brew

  log "Installing brew casks: ${casks[*]}"
  for c in "${casks[@]}"; do
    if brew list --cask "$c" >/dev/null 2>&1; then
      ok "$c already installed"
    else
      log "brew install --cask $c"
      brew install --cask "$c"
    fi
  done
}

# ── Linux (apt) ─────────────────────────────────────────────────────────────
install_gh_apt_repo() {
  if dpkg -s gh >/dev/null 2>&1; then
    ok "gh already installed"
    return 0
  fi
  log "Adding GitHub CLI apt repo"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  local arch
  arch="$(dpkg --print-architecture)"
  echo "deb [arch=$arch signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  unset YTERM_APT_UPDATED
  apt_install gh
}

install_pyenv_git() {
  if [[ -d "$HOME/.pyenv" ]]; then
    ok "pyenv already cloned at $HOME/.pyenv"
    ( cd "$HOME/.pyenv" && git pull --ff-only --quiet ) || \
      warn "pyenv git pull failed — leaving as-is"
  else
    log "Cloning pyenv into $HOME/.pyenv"
    git clone --depth=1 https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
  fi
}

install_uv_curl() {
  if have uv; then
    ok "uv already installed at $(command -v uv)"
    return 0
  fi
  log "Installing uv via official installer"
  curl -LsSf https://astral.sh/uv/install.sh | sh
}

# Ubuntu's apt nvim lags behind NVIM_FLOOR, so install the latest stable
# release tarball into ~/.local/share/nvim-linux and symlink the binary under
# ~/.local/bin (already on PATH via dotfiles/zshrc).
install_neovim_release() {
  if nvim_meets_floor; then
    ok "nvim $(nvim_version) already installed (>= $NVIM_FLOOR)"
    return 0
  fi
  if have nvim; then
    warn "nvim $(nvim_version) is older than $NVIM_FLOOR — installing latest stable"
  fi

  local arch tarball_new tarball_old
  arch="$(uname -m)"
  case "$arch" in
    x86_64)        tarball_new="nvim-linux-x86_64.tar.gz"; tarball_old="nvim-linux64.tar.gz" ;;
    aarch64|arm64) tarball_new="nvim-linux-arm64.tar.gz";  tarball_old="" ;;
    *) err "Unsupported architecture for Neovim release tarball: $arch"; return 1 ;;
  esac

  local tmp
  tmp="$(mktemp -d)"

  local base="https://github.com/neovim/neovim/releases/latest/download"
  log "Downloading Neovim release ($tarball_new)"
  if ! curl -fsSL "$base/$tarball_new" -o "$tmp/nvim.tar.gz"; then
    if [[ -n "$tarball_old" ]]; then
      warn "Falling back to legacy tarball name $tarball_old"
      if ! curl -fsSL "$base/$tarball_old" -o "$tmp/nvim.tar.gz"; then
        err "Could not download $tarball_old"
        rm -rf "$tmp"
        return 1
      fi
    else
      err "Could not download $tarball_new"
      rm -rf "$tmp"
      return 1
    fi
  fi

  tar -C "$tmp" -xzf "$tmp/nvim.tar.gz"
  local extracted
  extracted="$(find "$tmp" -maxdepth 1 -type d -name 'nvim-linux*' | head -n1)"
  if [[ -z "$extracted" ]]; then
    err "Extracted Neovim directory not found under $tmp"
    rm -rf "$tmp"
    return 1
  fi

  mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
  rm -rf "$HOME/.local/share/nvim-linux"
  mv "$extracted" "$HOME/.local/share/nvim-linux"
  ln -sfn "$HOME/.local/share/nvim-linux/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp"
  ok "Installed $("$HOME/.local/bin/nvim" --version | head -n1)"
}

install_hack_nerd_font_linux() {
  local font_dir="$HOME/.local/share/fonts/HackNerdFont"
  if [[ -d "$font_dir" ]] && compgen -G "$font_dir/*.ttf" >/dev/null; then
    ok "Hack Nerd Font already installed at $font_dir"
    return 0
  fi
  log "Downloading Hack Nerd Font"
  local tmp
  tmp="$(mktemp -d)"
  if ! curl -fsSL \
       "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip" \
       -o "$tmp/Hack.zip"; then
    err "Could not download Hack Nerd Font"
    rm -rf "$tmp"
    return 1
  fi
  mkdir -p "$font_dir"
  unzip -oq "$tmp/Hack.zip" -d "$font_dir"
  rm -rf "$tmp"
  if have fc-cache; then
    fc-cache -f "$font_dir" >/dev/null
    ok "Hack Nerd Font installed and font cache rebuilt"
  else
    warn "fc-cache not found — install fontconfig and run 'fc-cache -f' manually"
  fi
}

install_linux() {
  log "Installing apt packages"

  # Pyenv build-environment deps (https://github.com/pyenv/pyenv/wiki),
  # plus everything else from the macOS list that has a direct apt counterpart.
  apt_install \
    ripgrep \
    bat \
    wget \
    ffmpeg \
    sqlite3 \
    libsqlite3-dev \
    libssl-dev \
    libreadline-dev \
    liblzma-dev \
    xz-utils \
    libbz2-dev \
    zlib1g-dev \
    libffi-dev \
    libncursesw5-dev \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    llvm \
    zsh \
    fontconfig \
    locales

  install_gh_apt_repo
  install_pyenv_git
  install_uv_curl
  install_neovim_release
  install_hack_nerd_font_linux

  # On Ubuntu, `bat` is installed as `batcat` to avoid colliding with another
  # `bat` package. The dotfiles alias `cat=bat`, so symlink batcat -> bat in
  # ~/.local/bin to make that work without distro-specific shell config.
  if have batcat && ! have bat; then
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
    ok "Symlinked batcat -> $HOME/.local/bin/bat"
  fi
}

if is_macos; then
  install_macos
elif is_linux; then
  install_linux
fi
