# rafmac

Personal macOS bootstrap + dotfiles, managed with [chezmoi](https://chezmoi.io).
Clone once on a fresh Mac and get your apps, CLI tools, shell, and configs.

This is a personal setup.

---

## Fresh machine setup

```sh
# 1. Install Xcode Command Line Tools (git, compilers)
xcode-select --install

# 2. Install chezmoi and apply this repo in one shot
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <your-github-user>/rafmac
```

That single command will:

1. Clone this repo into `~/.local/share/chezmoi`.
2. Write/symlink your dotfiles into `$HOME`.
3. Run the provisioning scripts, in order:
   - Install Homebrew (`run_once_before_00`)
   - `brew bundle` the [`Brewfile`](./Brewfile) — apps + CLI tools (`run_onchange_before_10`)
   - Install oh-my-zsh (`run_once_after_20`)
   - Set up Flutter + Android SDK / emulator (`run_once_after_30`)
   - Print a **manual checklist** for the things that can't be safely automated
     (Xcode, App Store logins, etc.) (`run_once_after_99`)

4. After it finishes, work through the printed checklist and fill in your secrets
   (see below).

---

## Secrets

**No token, key, or credential is ever committed.**

- Real secrets live in `~/.config/rafmac/env.sh` — gitignored, ignored by chezmoi,
  never tracked.
- The repo ships [`dot_config/rafmac/env.sh.example`](./dot_config/rafmac/env.sh.example)
  with variable _names_ only.
- `.zshrc` sources the real file if it exists.

On a new machine:

```sh
cp ~/.config/rafmac/env.sh.example ~/.config/rafmac/env.sh
$EDITOR ~/.config/rafmac/env.sh   # paste values from your password manager
```

A [gitleaks](https://github.com/gitleaks/gitleaks) pre-commit hook (installed by the
Brewfile) blocks accidental secret commits. Enable hooks once with:

```sh
git config core.hooksPath .githooks
```

---

## Day-to-day workflow

Everything is incremental — you never rebuild from scratch.

| I want to…                      | Do this                                              |
| ------------------------------- | ---------------------------------------------------- |
| Edit a config live and keep it  | edit the file in `$HOME`, then `chezmoi re-add`      |
| Add a new dotfile to the repo   | `chezmoi add ~/.config/foo/bar`                      |
| Add/remove an app               | edit `Brewfile`, then `chezmoi apply` (auto re-runs) |
| Pull latest onto any machine    | `chezmoi update`                                     |
| See what would change           | `chezmoi diff`                                       |
| Edit a managed file via chezmoi | `chezmoi edit ~/.zshrc`                              |

After editing, commit and push from the source dir:

```sh
chezmoi cd
git add -A && git commit -m "update nvim config" && git push
```

---

## chezmoi cheat sheet

**Mental model:** there are two copies of every file — the **source** (this repo) and
the **target** (`$HOME`). chezmoi generates the target from the source. Edit one side,
then sync. Golden loop: **edit → apply (or re-add) → commit.**

### Setup / sync

```sh
# Fresh machine: clone repo, register as source, and apply in one shot.
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <your-github-user>/rafmac

# Point chezmoi at this repo if it's already cloned locally.
chezmoi init --source ~/Projects/rafmac

# Pull latest from git AND apply, in one step (use on any machine).
chezmoi update
```

### The two directions

```sh
# Repo  ->  $HOME : write your dotfiles out, and run any changed run_ scripts.
chezmoi apply

# $HOME ->  Repo  : pull a file you edited live back into the repo.
chezmoi re-add                 # re-add ALL managed files that changed
chezmoi re-add ~/.tmux.conf    # or just one
```

### Everyday commands

```sh
chezmoi diff                   # preview what apply WOULD change (changes nothing)
chezmoi edit ~/.zshrc          # edit the SOURCE of a managed file, safely
chezmoi add ~/.config/foo/bar  # start tracking a NEW dotfile (auto dot_ naming)
chezmoi forget ~/.zshrc        # stop managing a file (leaves $HOME copy alone)
chezmoi managed                # list every path chezmoi manages
chezmoi cd                     # drop into the source repo (for git add/commit/push)
chezmoi execute-template < dot_gitconfig.tmpl   # see a .tmpl rendered
```

### Commit after changes

```sh
chezmoi cd
git add -A && git commit -m "update nvim config" && git push
exit                           # leave the chezmoi cd subshell
```

### Re-running a run_ script

`run_once_*` scripts run only once per machine. To force one to run again (e.g. after
fixing the Android SDK step), clear chezmoi's script state, then apply:

```sh
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

`run_onchange_*` (the Brewfile installer) re-runs automatically whenever its content
changes — just edit the `Brewfile` and `chezmoi apply`.

---

## Layout

```
rafmac/
├── Brewfile                      # apps + CLI tools (brew / cask / mas)
├── .chezmoidata.yaml             # feature toggles (install_flutter, etc.)
├── .chezmoiignore                # paths chezmoi must never apply to $HOME
├── dot_zshrc.tmpl                # → ~/.zshrc
├── dot_zprofile.tmpl             # → ~/.zprofile (PATH, brew shellenv)
├── dot_gitconfig.tmpl            # → ~/.gitconfig
├── dot_tmux.conf                 # → ~/.tmux.conf
├── dot_config/
│   ├── nvim/init.lua             # → ~/.config/nvim/init.lua (starter)
│   ├── rafmac/env.sh.example     # secret var names (no values)
│   └── ai/                       # Claude / Pi coding instructions
├── run_once_before_00-install-homebrew.sh.tmpl
├── run_onchange_before_10-brew-bundle.sh.tmpl
├── run_once_after_20-install-omzsh.sh.tmpl
├── run_once_after_30-flutter-android-sdk.sh.tmpl
└── run_once_after_99-manual-checklist.sh.tmpl
```
