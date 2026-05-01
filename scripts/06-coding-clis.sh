#!/usr/bin/env bash
# Install one or more AI coding CLIs: Claude Code, Codex (OpenAI), OpenCode (sst).
#
# Interactive: prompts for a comma-separated selection.
# Non-interactive: set CODING_CLIS to a comma-separated list of names
#   (claude, codex, opencode), or "all" / "none". Defaults to "claude" when
#   unset and stdin is not a TTY (preserves prior behavior).

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

declare -a SELECTED=()

parse_selection() {
  local raw="${1// /}"
  case "$raw" in
    ""|s|skip|n|no|none) SELECTED=() ;;
    a|all)               SELECTED=(claude codex opencode) ;;
    *)
      local IFS=','
      read -ra parts <<<"$raw"
      for p in "${parts[@]}"; do
        case "$p" in
          1|claude|claude-code) SELECTED+=(claude) ;;
          2|codex)              SELECTED+=(codex) ;;
          3|opencode)           SELECTED+=(opencode) ;;
          "") ;;
          *) warn "Ignoring unknown selection: $p" ;;
        esac
      done
      ;;
  esac

  # de-duplicate while preserving order
  local -a seen=() out=()
  for s in "${SELECTED[@]}"; do
    if [[ " ${seen[*]:-} " != *" $s "* ]]; then
      seen+=("$s")
      out+=("$s")
    fi
  done
  SELECTED=("${out[@]}")
}

prompt_selection() {
  echo "  Select AI coding CLIs to install (comma-separated, e.g. 1,3):"
  echo "    1) Claude Code   (anthropic)  https://claude.ai"
  echo "    2) Codex CLI     (openai)     npm @openai/codex"
  echo "    3) OpenCode      (sst)        https://opencode.ai"
  echo "    a) all   s) skip"
  local reply
  reply="$(prompt_with_timeout "  choice" "1")"
  parse_selection "$reply"
}

install_claude() {
  log "Installing Claude Code CLI"
  if have claude; then
    ok "claude already installed at $(command -v claude) ($(claude --version 2>/dev/null || echo unknown))"
    return 0
  fi
  curl -fsSL https://claude.ai/install.sh | bash
  if [[ -x "$HOME/.local/bin/claude" ]]; then
    ok "Claude installed at $HOME/.local/bin/claude"
    warn "Make sure \$HOME/.local/bin is on your PATH (the included .zshrc handles this via ~/.local/bin/env)."
  else
    err "Claude install did not produce ~/.local/bin/claude — check installer output."
    return 1
  fi
}

install_codex() {
  log "Installing Codex CLI (OpenAI)"
  if have codex; then
    ok "codex already installed at $(command -v codex) ($(codex --version 2>/dev/null || echo unknown))"
    return 0
  fi

  # Each install script runs in its own bash subprocess, so nvm's PATH setup
  # from step 04 doesn't carry over here. Source nvm explicitly if it's
  # installed but `npm` isn't on PATH yet.
  if ! have npm && [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    nvm use default >/dev/null 2>&1 || true
  fi

  if ! have npm; then
    err "npm not found — run scripts/04-node-bun.sh first, then re-run this step."
    return 1
  fi
  npm install -g @openai/codex
  if have codex; then
    ok "Codex installed: $(command -v codex)"
  else
    err "codex did not land on PATH after npm install — check npm global prefix."
    return 1
  fi
}

install_opencode() {
  log "Installing OpenCode (sst)"
  if have opencode; then
    ok "opencode already installed at $(command -v opencode) ($(opencode --version 2>/dev/null || echo unknown))"
    return 0
  fi
  curl -fsSL https://opencode.ai/install | bash

  # The installer drops the binary at ~/.opencode/bin/opencode and tries to
  # append PATH exports to ~/.zshrc. We can't rely on those rc edits because
  # step 07 replaces ~/.zshrc with a symlink to the repo dotfile. Symlink the
  # binary into ~/.local/bin (already on PATH via dotfiles/zshrc) so opencode
  # is reachable without dotfile pollution.
  if [[ -x "$HOME/.opencode/bin/opencode" ]]; then
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$HOME/.opencode/bin/opencode" "$HOME/.local/bin/opencode"
    ok "OpenCode installed at $HOME/.opencode/bin/opencode (symlinked to $HOME/.local/bin/opencode)"
  elif have opencode; then
    ok "OpenCode installed: $(command -v opencode)"
  else
    err "OpenCode install did not produce an opencode binary — check installer output."
    return 1
  fi
}

log "Choose AI coding CLIs to install"
if [[ -n "${CODING_CLIS:-}" ]]; then
  parse_selection "$CODING_CLIS"
elif [[ -t 0 ]] || [[ -e /dev/tty ]]; then
  prompt_selection
else
  warn "Non-interactive run with CODING_CLIS unset — defaulting to claude"
  SELECTED=(claude)
fi

if [[ ${#SELECTED[@]} -eq 0 ]]; then
  warn "No CLIs selected — skipping"
  exit 0
fi

ok "Selected: ${SELECTED[*]}"
for choice in "${SELECTED[@]}"; do
  case "$choice" in
    claude)   install_claude ;;
    codex)    install_codex ;;
    opencode) install_opencode ;;
  esac
done
