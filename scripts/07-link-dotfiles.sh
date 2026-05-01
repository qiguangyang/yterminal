#!/usr/bin/env bash
# Symlink dotfiles and nvim config from the repo into $HOME, and prompt for
# git user.name / user.email (skippable).
# Existing files are backed up with a timestamp suffix before linking.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

log "Linking shell dotfiles"
link_file "$REPO_ROOT/dotfiles/zshrc"     "$HOME/.zshrc"
link_file "$REPO_ROOT/dotfiles/zprofile"  "$HOME/.zprofile"

log "Configuring git identity"
existing_name="$(git config --global --get user.name  2>/dev/null || true)"
existing_email="$(git config --global --get user.email 2>/dev/null || true)"

if [[ -n "$existing_name" && -n "$existing_email" ]]; then
  ok "git identity already set: $existing_name <$existing_email> (leaving as-is)"
else
  warn "Personal git identity is intentionally not committed to this repo."
  echo "  Enter your git name and email now, or leave blank to skip."

  git_name="$(prompt_with_timeout  "  git user.name " "")"
  git_email="$(prompt_with_timeout "  git user.email" "")"

  if [[ -n "$git_name"  ]]; then git config --global user.name  "$git_name";  ok "Set user.name = $git_name";   fi
  if [[ -n "$git_email" ]]; then git config --global user.email "$git_email"; ok "Set user.email = $git_email"; fi
  if [[ -z "$git_name" && -z "$git_email" ]]; then
    warn "Skipped — set later with: git config --global user.name '...' && git config --global user.email '...'"
  fi
fi

log "Linking Neovim config"
mkdir -p "$HOME/.config"
if [[ -e "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]]; then
  backup_if_exists "$HOME/.config/nvim"
fi
link_file "$REPO_ROOT/config/nvim" "$HOME/.config/nvim"
