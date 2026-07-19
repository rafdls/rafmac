# rafmac

My personal macOS setup and dotfiles, managed with [chezmoi](https://chezmoi.io).

## Fresh machine

```sh
xcode-select --install
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply rafdls/rafmac
```

This clones the repo to `~/.local/share/chezmoi`, writes the dotfiles to `$HOME`, and runs the provisioning scripts in order:

1. Install Homebrew — `run_once_before_00`
2. `brew bundle` the [`Brewfile`](./Brewfile) — `run_onchange_before_10`
3. Install oh-my-zsh — `run_once_after_20`
4. Flutter + Android SDK/emulator — `run_once_after_30`
5. iTerm2 font — `run_once_after_40`
6. Print a manual checklist (Xcode, App Store logins) — `run_once_after_99`

Then work through the checklist and set up your secrets (below).

## Pointing chezmoi at this repo

If chezmoi is already installed, clone this repo into chezmoi's default source directory — that's the only place it looks unless told otherwise:

```sh
git clone https://github.com/rafdls/rafmac.git ~/.local/share/chezmoi
chezmoi diff     # preview what would change
chezmoi apply    # write to $HOME, run the run_ scripts
```

Confirm with `chezmoi source-path`; it should print `~/.local/share/chezmoi`. Use `chezmoi cd` to work in the repo from then on (see [Common commands](#common-commands)).

## Secrets

Nothing sensitive is committed. Real values live in `~/.config/rafmac/env.sh` (gitignored and chezmoi-ignored); the repo only ships [`env.sh.example`](./dot_config/rafmac/env.sh.example) with variable names. `.zshrc` sources the real file if it exists.

```sh
cp ~/.config/rafmac/env.sh.example ~/.config/rafmac/env.sh
$EDITOR ~/.config/rafmac/env.sh
git config core.hooksPath .githooks   # enable the gitleaks pre-commit hook, once
```

## Common commands

```sh
chezmoi diff          # preview what apply would change
chezmoi apply         # write dotfiles to $HOME, run changed run_ scripts
chezmoi update        # git pull + apply
chezmoi re-add        # pull live-edited files back into the repo
chezmoi add ~/.config/foo/bar   # start tracking a new dotfile
chezmoi edit ~/.zshrc           # edit a managed file's source
chezmoi forget ~/.zshrc         # stop managing a file
chezmoi managed                 # list managed paths
chezmoi cd            # drop into the source repo
```

Commit changes from the source repo:

```sh
chezmoi cd
git add -A && git commit -m "update nvim config" && git push
exit
```

## Re-running a run_ script

`run_once_*` scripts run once per machine. To force them again:

```sh
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

`run_onchange_*` re-runs automatically when its content changes.

## Layout

```
rafmac/
├── Brewfile                      # apps + CLI tools (brew / cask / mas)
├── .chezmoidata.yaml             # feature toggles (install_flutter, etc.)
├── .chezmoiignore                # paths never applied to $HOME
├── dot_zshrc.tmpl                # → ~/.zshrc
├── dot_zprofile.tmpl             # → ~/.zprofile (PATH, brew shellenv)
├── dot_gitconfig.tmpl            # → ~/.gitconfig
├── dot_tmux.conf                 # → ~/.tmux.conf
├── dot_config/
│   ├── nvim/init.lua             # → ~/.config/nvim/init.lua
│   ├── rafmac/env.sh.example     # secret var names (no values)
│   └── ai/                       # Claude / Pi coding instructions
└── run_*.sh.tmpl                 # provisioning scripts (see Fresh machine)
```
