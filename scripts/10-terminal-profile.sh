#!/usr/bin/env bash
# Import the bundled "Clear Dark" Terminal.app profile and set it as the
# default for new windows.
#
# How import works on macOS: `open -a Terminal foo.terminal` opens the file
# with Terminal.app, which registers it in the Profiles list. Setting the
# defaults afterward makes it the default profile for new + startup windows.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_macos

profile_file="$REPO_ROOT/config/ClearDark.terminal"
profile_name="Clear Dark"   # value of the <key>name</key> in the plist

if [[ ! -f "$profile_file" ]]; then
  err "Profile file not found at $profile_file"
  exit 1
fi

log "Importing Terminal profile: $profile_name"
# This will pop a new Terminal window using the imported profile — that's
# Terminal.app's expected behavior. The user can close it.
open -a Terminal "$profile_file"

# Give Terminal a moment to register the profile before we read defaults.
sleep 1

log "Setting '$profile_name' as the default Terminal profile"
defaults write com.apple.Terminal "Default Window Settings" -string "$profile_name"
defaults write com.apple.Terminal "Startup Window Settings" -string "$profile_name"

ok "Terminal profile imported and set as default"
warn "Close any pre-existing Terminal windows; new windows will use '$profile_name'."
