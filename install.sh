#!/bin/sh
# install.sh — Peanut Butter Collective public installer (stage 0). Human-run.
#
#   curl -fsSL https://raw.githubusercontent.com/peanut-butter-collective/.github/main/install.sh | sh
#
# Gets a fresh macOS/Linux machine from nothing to a working PBC workspace:
# installs git + the GitHub CLI, signs you in, then hands off to the private
# workspace installer in pbc-manifest (which clones the repos and runs the full
# bootstrap). You must be a member of the peanut-butter-collective GitHub org.
set -e

info() { printf '\033[1;34m[pbc]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- Detect OS + package manager --------------------------------------------
OS="$(uname -s)"
case "$OS" in
  Darwin)
    have brew || die "Homebrew is required. Install it from https://brew.sh then re-run."
    PM=brew ;;
  Linux)
    if   have apt-get; then PM=apt
    elif have dnf;     then PM=dnf
    elif have pacman;  then PM=pacman
    else die "No supported package manager found (apt, dnf, or pacman)."; fi ;;
  *) die "Unsupported OS: $OS. On Windows, use install.ps1 (see the org profile page)." ;;
esac

# --- git --------------------------------------------------------------------
if have git; then
  info "git already installed"
else
  info "Installing git..."
  case "$PM" in
    brew)   brew install git ;;
    apt)    sudo apt-get update && sudo apt-get install -y git ;;
    dnf)    sudo dnf install -y git ;;
    pacman) sudo pacman -S --noconfirm git ;;
  esac
fi

# --- GitHub CLI (gh) --------------------------------------------------------
if have gh; then
  info "gh already installed"
else
  info "Installing the GitHub CLI (gh)..."
  case "$PM" in
    brew)   brew install gh ;;
    pacman) sudo pacman -S --noconfirm github-cli ;;
    apt)
      # gh is not in the default apt repos; add GitHub's signed repo.
      sudo mkdir -p -m 755 /etc/apt/keyrings
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
      sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
      sudo apt-get update && sudo apt-get install -y gh ;;
    dnf)
      sudo dnf install -y 'dnf-command(config-manager)' || true
      sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
      sudo dnf install -y gh ;;
  esac
fi

# --- Authenticate -----------------------------------------------------------
if gh auth status >/dev/null 2>&1; then
  info "GitHub CLI already authenticated"
else
  info "Signing you in to GitHub (you must be a peanut-butter-collective member)..."
  # This script is usually run via `curl | sh`, so stdin is the script, not the
  # terminal. Give gh the terminal for its interactive prompts.
  [ -r /dev/tty ] || die "No terminal for 'gh auth login'. Run 'gh auth login' yourself, then re-run."
  gh auth login < /dev/tty
fi

# --- Hand off to the private workspace installer ----------------------------
info "Fetching and running the PBC workspace installer..."
gh api repos/peanut-butter-collective/pbc-manifest/contents/install.sh \
  -H "Accept: application/vnd.github.raw" | sh
