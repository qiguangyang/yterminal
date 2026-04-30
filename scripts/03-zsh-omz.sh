#!/usr/bin/env bash
# Install Oh My Zsh + custom plugins (zsh-autosuggestions, zsh-syntax-highlighting).
# Default shell is switched to zsh if not already.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_brew_in_path

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

log "Installing Oh My Zsh"
if [[ -d "$ZSH_DIR" ]]; then
  ok "Oh My Zsh already installed at $ZSH_DIR"
else
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

clone_plugin() {
  local name="$1" url="$2"
  local dest="$CUSTOM/plugins/$name"
  if [[ -d "$dest" ]]; then
    ok "Plugin $name already installed"
  else
    log "Cloning $name"
    git clone --depth=1 "$url" "$dest"
  fi
}

clone_plugin zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions
clone_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

log "Verifying default shell"
zsh_path="$(command -v zsh)"
if [[ "${SHELL:-}" != "$zsh_path" ]]; then
  if ! grep -qx "$zsh_path" /etc/shells; then
    warn "Adding $zsh_path to /etc/shells (sudo)"
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi
  log "Switching default shell to $zsh_path"
  chsh -s "$zsh_path" || warn "chsh failed — change shell manually"
else
  ok "Default shell is already $zsh_path"
fi
