#!/usr/bin/env bash
# Install CLI tools and casks via Homebrew.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_brew_in_path

formulae=(
  neovim
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

casks=(
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

log "Installing brew casks: ${casks[*]}"
for c in "${casks[@]}"; do
  if brew list --cask "$c" >/dev/null 2>&1; then
    ok "$c already installed"
  else
    log "brew install --cask $c"
    brew install --cask "$c"
  fi
done
