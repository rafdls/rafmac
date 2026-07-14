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
