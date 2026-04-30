#!/usr/bin/env bash
# Ensure SSH is available and create an ed25519 key if one doesn't exist.
# Idempotent: never overwrites an existing key. macOS ships OpenSSH, so
# nothing to install — we just generate, configure keychain integration,
# add the key to ssh-agent, and print the public key for copy-paste.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_macos

if ! have ssh-keygen || ! have ssh-add; then
  err "OpenSSH binaries not found. macOS normally ships these — check /usr/bin."
  exit 1
fi
ok "OpenSSH present: $(ssh -V 2>&1)"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

key="$HOME/.ssh/id_ed25519"

if [[ -f "$key" ]]; then
  ok "SSH key already exists at $key — leaving it untouched"
else
  log "Generating new ed25519 SSH key at $key"
  printf "  Email/comment for the key (optional, e.g. you@example.com): "
  read -r ssh_comment || ssh_comment=""

  comment_args=()
  if [[ -n "$ssh_comment" ]]; then
    comment_args=(-C "$ssh_comment")
  fi

  warn "ssh-keygen will now prompt for a passphrase (recommended). Press Enter twice to skip."
  ssh-keygen -t ed25519 -f "$key" "${comment_args[@]}"
  ok "Key written to $key"
fi

config="$HOME/.ssh/config"
touch "$config"
chmod 600 "$config"

if ! grep -qE "^[[:space:]]*UseKeychain[[:space:]]+yes" "$config"; then
  log "Adding macOS keychain block to $config"
  cat >> "$config" <<'EOF'

# Added by yterminal
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
  ok "ssh config updated"
else
  ok "ssh config already has UseKeychain entry"
fi

log "Adding key to ssh-agent + Apple keychain"
if ssh-add --apple-use-keychain "$key" >/dev/null 2>&1 \
   || ssh-add -K "$key" >/dev/null 2>&1 \
   || ssh-add "$key" >/dev/null 2>&1; then
  ok "Key registered with ssh-agent"
else
  warn "Could not add key to agent (this is fine if it's already loaded or has a passphrase you didn't enter)"
fi

log "Public key (paste into GitHub → Settings → SSH keys, etc.):"
echo
/bin/cat "${key}.pub"
echo
