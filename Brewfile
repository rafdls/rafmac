# Brewfile — installed via `brew bundle` (run_onchange_before_10 re-runs on change).
# Docs: https://github.com/Homebrew/homebrew-bundle

# ---- Taps ----------------------------------------------------------------
tap "homebrew/bundle"

# ---- CLI tools -----------------------------------------------------------
brew "git"
brew "neovim"
brew "tmux"
brew "mas"                      # Mac App Store CLI (for App Store-only apps)
brew "gitleaks"                 # secret scanner used by the pre-commit hook
brew "gnu-sed"                  # some scripts expect GNU sed
brew "wget"
brew "jq"
brew "ripgrep"                  # fast search, used by many nvim setups
brew "fzf"

# Android command-line tooling. `android-platform-tools` provides `adb`.
brew "android-platform-tools"

# ---- GUI apps (casks) ----------------------------------------------------
cask "iterm2"
cask "visual-studio-code"
cask "arc"
cask "android-studio"          # bundles the Android SDK + emulator + avdmanager
cask "flutter"                 # Flutter SDK; `flutter doctor` finishes setup

# ---- Fonts (nice-to-have for terminal/nvim) ------------------------------
cask "font-jetbrains-mono-nerd-font"

# ---- Mac App Store apps --------------------------------------------------
# Requires being signed into the App Store first (see manual checklist).
# Uncomment once you've confirmed the id via `mas search Xcode`.
# mas "Xcode", id: 497799835

# ---- Notes ---------------------------------------------------------------
# Pi (coding agent) and the Claude CLI are installed by run_once scripts,
# not via Homebrew — see run_once_after_30 and the manual checklist.
