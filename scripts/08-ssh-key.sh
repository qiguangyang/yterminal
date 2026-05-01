#!/usr/bin/env bash
# Ensure SSH is available and create an ed25519 key if one doesn't exist.
# Idempotent: never overwrites an existing key.
#
# macOS: OpenSSH ships with the OS — we just generate, configure Apple keychain
#   integration, add the key to ssh-agent, and print the public key.
# Linux: ensure openssh-client is present (apt), generate key, register with
#   ssh-agent if one is running. No keychain block — that's macOS-specific.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_supported_os

if is_linux && ! have ssh-keygen; then
  apt_install openssh-client
fi

if ! have ssh-keygen || ! have ssh-add; then
  err "OpenSSH binaries not found. Install openssh-client and re-run."
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
  ssh_comment="$(prompt_with_timeout "  Email/comment for the key (e.g. you@example.com)" "")"

  comment_args=()
  if [[ -n "$ssh_comment" ]]; then
    comment_args=(-C "$ssh_comment")
  fi

  # Default to an empty passphrase so the step is unattended-friendly. Users
  # who want a passphrase can type "y" within the timeout to fall through to
  # ssh-keygen's own interactive prompt (which asks twice with confirmation).
  passphrase_choice="$(prompt_with_timeout "  Set a passphrase? (recommended for shared machines) [empty/y]" "empty")"
  if [[ "$passphrase_choice" =~ ^[Yy] ]]; then
    warn "ssh-keygen will now prompt for a passphrase. Press Enter twice to abort and use empty instead."
    ssh-keygen -t ed25519 -f "$key" "${comment_args[@]}"
  else
    ssh-keygen -t ed25519 -N "" -f "$key" "${comment_args[@]}"
  fi
  ok "Key written to $key"
fi

config="$HOME/.ssh/config"
touch "$config"
chmod 600 "$config"

if is_macos; then
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
else
  if ! grep -qE "^[[:space:]]*AddKeysToAgent[[:space:]]+yes" "$config"; then
    log "Adding ssh-agent block to $config"
    cat >> "$config" <<'EOF'

# Added by yterminal
Host *
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
EOF
    ok "ssh config updated"
  else
    ok "ssh config already has AddKeysToAgent entry"
  fi
fi

log "Adding key to ssh-agent"
if is_macos; then
  if ssh-add --apple-use-keychain "$key" >/dev/null 2>&1 \
     || ssh-add -K "$key" >/dev/null 2>&1 \
     || ssh-add "$key" >/dev/null 2>&1; then
    ok "Key registered with ssh-agent"
  else
    warn "Could not add key to agent (this is fine if it's already loaded or has a passphrase you didn't enter)"
  fi
else
  if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    warn "No ssh-agent running in this shell. Start one with: eval \"\$(ssh-agent -s)\" && ssh-add $key"
  elif ssh-add "$key" >/dev/null 2>&1; then
    ok "Key registered with ssh-agent"
  else
    warn "Could not add key to agent (fine if it's already loaded or has a passphrase you didn't enter)"
  fi
fi

log "Public key (paste into GitHub → Settings → SSH keys, etc.):"
echo
/bin/cat "${key}.pub"
echo
