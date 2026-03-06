#!/usr/bin/env bash
#
# Linux Server Setup — dotfiles + tools
# Usage: ./install-linux.sh
#
set -euo pipefail

LOG_FILE="/tmp/server-setup-$(date +%Y%m%d-%H%M%S).log"
log()  { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG_FILE"; }
warn() { log "WARN  $*"; }
die()  { log "FATAL $*"; exit 1; }

# ─── Pre-flight ──────────────────────────────────────────────────────────────

[[ "$EUID" -eq 0 ]] && die "Don't run as root. Run as your normal user."
sudo -v 2>/dev/null  || die "Needs sudo access."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for pkg in zsh tmux nvim; do
    [[ -d "$SCRIPT_DIR/$pkg" ]] || die "Stow package '$pkg' not found. Run from the dotfiles repo root."
done

# ─── Apt packages (includes neovim and fzf) ─────────────────────────────────

log "Installing apt packages..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    stow tmux zsh curl git ripgrep fd-find unzip build-essential \
    neovim fzf

# ─── Standalone tools ────────────────────────────────────────────────────────

if ! command -v zoxide &>/dev/null; then
    log "Installing zoxide..."
    curl -fsSL --retry 3 https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

if ! command -v starship &>/dev/null; then
    log "Installing starship..."
    curl -fsSL --retry 3 https://starship.rs/install.sh | sh -s -- -y
fi

# ─── Plugins ─────────────────────────────────────────────────────────────────

log "Setting up plugins..."
mkdir -p ~/.zsh

declare -A plugins=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
    [fzf-tab]="https://github.com/Aloxaf/fzf-tab"
)
for name in "${!plugins[@]}"; do
    dest="$HOME/.zsh/$name"
    if [[ -d "$dest" ]]; then
        git -C "$dest" pull --quiet || warn "$name pull failed"
    else
        git clone --depth 1 "${plugins[$name]}" "$dest"
    fi
done

tpm_dir="$HOME/.tmux/plugins/tpm"
if [[ -d "$tpm_dir" ]]; then
    git -C "$tpm_dir" pull --quiet || warn "TPM pull failed"
else
    mkdir -p "$HOME/.tmux/plugins"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
fi

# ─── Stow dotfiles ──────────────────────────────────────────────────────────

log "Linking dotfiles..."
mkdir -p "$HOME/.config"

for target in "$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/nvim"; do
    if [[ -e "$target" && ! -L "$target" ]]; then
        backup="${target}.bak.$(date +%s)"
        warn "Backing up $target → $backup"
        mv "$target" "$backup"
    fi
done

cd "$SCRIPT_DIR"
stow --restow -t "$HOME" zsh tmux nvim

# ─── Default shell ───────────────────────────────────────────────────────────

if [[ "$SHELL" != */zsh ]]; then
    zsh_path="$(which zsh)"
    grep -qxF "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    sudo chsh -s "$zsh_path" "$USER"
fi

log "Done! Log out and back in (or run 'exec zsh')."