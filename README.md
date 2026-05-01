# yterminal

One-shot bootstrap for a terminal dev environment — zsh + Oh My Zsh, Neovim
(AstroNvim template), Node/Bun/pnpm, Python via pyenv, and AI coding CLIs
(Claude Code / Codex / OpenCode), plus the matching dotfiles.

Designed to take a fresh machine and make it match this setup.

## Supported platforms

| OS | Package manager | Tested |
| -- | --------------- | ------ |
| macOS (Apple Silicon + Intel) | Homebrew | ✓ |
| Ubuntu / Debian (and derivatives) | apt | ✓ |

The installer detects the OS at runtime (`uname` + `/etc/os-release`) and
branches per step. Other Linux distros bail out early with a clear error.

## Quick start

```sh
git clone <this-repo> ~/yterminal
cd ~/yterminal
./install.sh
```

On Linux, `sudo` will be invoked for `apt-get install` and `chsh`. On macOS,
`sudo` is invoked for adding zsh to `/etc/shells` and for `chsh`.

Open a new terminal afterward — the new shell picks up `.zshrc`, `.zprofile`,
and PATH changes.

## What gets installed

| Step | Script | macOS | Linux (apt) |
| ---- | ------ | ----- | ----------- |
| 0 | `00-system-deps.sh` | Triggers Xcode CLT install dialog | `build-essential curl wget git ca-certificates file unzip gnupg lsb-release software-properties-common` |
| 1 | `01-package-manager.sh` | Installs Homebrew, then `brew update` | `apt-get update` |
| 2 | `02-base-packages.sh` | Brew formulae (`neovim`, `ripgrep`, `bat`, `gh`, `wget`, `pyenv`, `uv`, `tree-sitter`, `coreutils`, `ffmpeg`, `sqlite`, `openssl@3`, `readline`, `xz`, `zsh`) + cask `font-hack-nerd-font` | apt: `ripgrep bat ffmpeg sqlite3 zsh fontconfig` + pyenv build deps; GitHub CLI via official apt repo; pyenv via `git clone`; uv via official installer; Neovim ≥ 0.10 from GitHub releases tarball into `~/.local/share/nvim-linux`; Hack Nerd Font into `~/.local/share/fonts` |
| 3 | `03-zsh-omz.sh` | Oh My Zsh + `zsh-autosuggestions`, `zsh-syntax-highlighting`; sets zsh as login shell | (same) |
| 4 | `04-node-bun.sh` | `nvm` + latest stable Node (default), Bun, pnpm | (same) |
| 5 | `05-pyenv.sh` | Latest stable CPython via pyenv, pinned global | (same) |
| 6 | `06-coding-clis.sh` | Multi-select install for AI coding CLIs: Claude Code, Codex (OpenAI), OpenCode (sst). Set `CODING_CLIS=claude,codex,opencode` (or `all`/`none`) for non-interactive runs. | (same) |
| 7 | `07-link-dotfiles.sh` | Symlinks `~/.zshrc`, `~/.zprofile`, `~/.config/nvim`; prompts for git identity (skippable) | (same) |
| 8 | `08-ssh-key.sh` | Generates `~/.ssh/id_ed25519` (skips if present), Apple keychain config, loads into `ssh-agent`, prints public key | Generates key, writes plain `AddKeysToAgent` config (no Apple keychain), loads into `ssh-agent` if running |
| 9 | `09-nvim-bootstrap.sh` | Headless `:Lazy sync` + `:TSUpdateSync` | (same) |
| 10 | `10-terminal-profile.sh` | Imports `config/ClearDark.terminal` into Terminal.app and sets it as the default profile | Skipped (Linux terminal config is out of scope) |
| 11 | `11-gh-auth.sh` | `gh auth login` (SSH + browser flow); skips if already signed in | (same) — auto-skipped in headless environments |
| 12 | `12-headless-chrome.sh` | Skipped (assumes Chrome.app is installed; warns otherwise) | Installs headless deps + Google Chrome (amd64) or chromium-browser (arm64); symlinks the binary to `~/.local/bin/chrome` for testing tools |

Each script is idempotent — re-running `install.sh` skips work that's already done.

Every interactive prompt (CLI selection, git identity, SSH key comment) has a
**30-second timeout**: if no input arrives, the script applies the default and
keeps going. Override the timeout with `YTERM_PROMPT_TIMEOUT=N` (in seconds).
This makes the installer safe to start and walk away from.

## Layout

```
yterminal/
├── install.sh              # entry point, runs every script in order
├── scripts/                # modular install steps + shared lib.sh
├── dotfiles/               # source of truth for shell config
│   ├── zshrc
│   └── zprofile
├── config/
│   ├── ClearDark.terminal  # Terminal.app color profile, imported by step 10 (macOS only)
│   └── nvim/               # AstroNvim-based config, mirrors ~/.config/nvim
└── test/                   # Docker-based test harness
    ├── Dockerfile
    └── run.sh
```

Files live without leading dots in `dotfiles/` to make them easier to browse on disk
and in GitHub. The link step adds the dot when symlinking into `$HOME`.

## Run a single step

```sh
bash scripts/07-link-dotfiles.sh
```

List the steps without running:

```sh
./install.sh --list
```

## Testing the installer (Docker)

`test/Dockerfile` builds a minimal Ubuntu 24.04 image with just enough baseline
(sudo, tzdata, locales, ca-certificates) for `./install.sh` to run cleanly.
The repo is bind-mounted at runtime, so script edits on the host take effect
immediately — no image rebuild between iterations.

One-shot:

```sh
./test/run.sh                    # build + (re)create container + drop into bash
./install.sh                     # inside the container
```

Or by hand:

```sh
docker build -t yterminal-test test/
docker run -d --name yterminal-test -v "$PWD":/work -w /work yterminal-test
docker exec -it yterminal-test bash
```

Cleanup:

```sh
docker rm -f yterminal-test
```

In a container, step 08 (ssh-key passphrase) is the only step that needs you
to hit Enter twice; step 11 (gh-auth) auto-skips because no browser opener is
available; step 12 (headless-chrome) falls back to Playwright's bundled
Chromium on arm64 since Google Chrome ships only amd64 Linux builds.

## Editing your config

Edit files inside this repo — the home-directory copies are symlinks, so changes
take effect immediately. Commit and push to keep the source of truth in sync.

## Backups

`scripts/07-link-dotfiles.sh` renames any existing real files to `*.bak.YYYYMMDD-HHMMSS`
before linking, so a re-run never silently overwrites local state.

`~/.gitconfig` is **not** symlinked — personal identity is private and shouldn't
live in the repo. The link step prompts for `user.name` and `user.email` and
writes them with `git config --global`. Press Enter on both prompts to skip
and configure later.

## Caveats

- Linux support targets Debian/Ubuntu-family distros (`apt`-based). Other
  distros (Arch, Fedora, etc.) will exit early in step 0.
- `chsh` and `apt-get install` (Linux) / `tee >> /etc/shells` (macOS) prompt
  for your password.
- On Linux, Neovim is installed under `~/.local/share/nvim-linux` and symlinked
  to `~/.local/bin/nvim` — Ubuntu's apt-packaged neovim lags behind the version
  AstroNvim requires (≥ 0.10).
- On Linux, `bat` is shipped as `batcat`; the install symlinks it back to `bat`
  in `~/.local/bin` so the shared `cat=bat` alias works.
- Neovim's `:Lazy sync` may print warnings on first run; re-open nvim if
  anything looks wrong.
