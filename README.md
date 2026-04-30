# yterminal

One-shot bootstrap for a macOS terminal dev environment — Homebrew, zsh + Oh My Zsh,
Neovim (AstroNvim template), Node/Bun/pnpm, and Claude Code, plus the matching dotfiles.

Designed to take a fresh Mac and make it match this setup.

## Quick start

```sh
git clone <this-repo> ~/yterminal
cd ~/yterminal
./install.sh
```

Open a new terminal afterward — the new shell picks up `.zshrc`, `.zprofile`, and PATH changes.

## What gets installed

| Step | Script | What it does |
| ---- | ------ | ------------ |
| 0 | `scripts/00-xcode-clt.sh` | Triggers the Xcode Command Line Tools install dialog if missing |
| 1 | `scripts/01-homebrew.sh` | Installs Homebrew via the official `brew.sh` installer, then `brew update` |
| 2 | `scripts/02-brew-packages.sh` | Formulae: `neovim`, `ripgrep`, `bat`, `gh`, `wget`, `pyenv`, `uv`, `tree-sitter`, `coreutils`, `ffmpeg`, `sqlite`, `openssl@3`, `readline`, `xz`, `zsh`. Casks: `font-hack-nerd-font` |
| 3 | `scripts/03-zsh-omz.sh` | Oh My Zsh + `zsh-autosuggestions`, `zsh-syntax-highlighting`; sets zsh as login shell |
| 4 | `scripts/04-node-bun.sh` | `nvm` + latest stable Node (set as default), Bun, pnpm |
| 5 | `scripts/05-pyenv.sh` | Installs latest stable CPython via pyenv and pins it as the global default |
| 6 | `scripts/06-claude-code.sh` | Claude Code CLI into `~/.local/bin` |
| 7 | `scripts/07-link-dotfiles.sh` | Symlinks `~/.zshrc`, `~/.zprofile`, `~/.config/nvim`; interactively prompts for git `user.name`/`user.email` (skippable) |
| 8 | `scripts/08-ssh-key.sh` | Generates `~/.ssh/id_ed25519` (skips if present), adds Apple keychain config, loads into `ssh-agent`, prints the public key |
| 9 | `scripts/09-nvim-bootstrap.sh` | Headless `:Lazy sync` so plugins are ready on first launch |
| 10 | `scripts/10-terminal-profile.sh` | Imports `config/ClearDark.terminal` into Terminal.app and sets it as the default profile |
| 11 | `scripts/11-gh-auth.sh` | Runs `gh auth login` (SSH + browser flow); skips if already signed in |

Each script is idempotent — re-running `install.sh` skips work that's already done.

## Layout

```
yterminal/
├── install.sh              # entry point, runs every script in order
├── scripts/                # modular install steps + shared lib.sh
├── dotfiles/               # source of truth for shell config
│   ├── zshrc
│   └── zprofile
└── config/
    ├── ClearDark.terminal  # Terminal.app color profile, imported by step 10
    └── nvim/               # AstroNvim-based config, mirrors ~/.config/nvim
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

- macOS only. The prereq script bails on Linux.
- `chsh` to zsh and `sudo tee >> /etc/shells` may prompt for your password.
- Neovim's `:Lazy sync` may print warnings on first run; re-open nvim if anything looks wrong.
