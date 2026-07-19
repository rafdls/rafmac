# rafmac

My personal macOS setup and dotfiles, managed with [chezmoi](https://chezmoi.io).

## Fresh machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply rafdls/rafmac
```

This clones the repo to `~/.local/share/chezmoi`, writes the dotfiles to `$HOME`, and runs the `run_*` provisioning scripts in order. The first of those installs Homebrew, which also installs the Xcode Command Line Tools if they're missing, so there's nothing to install by hand first.

Then work through the checklist it prints at the end and set up your secrets (below).

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
