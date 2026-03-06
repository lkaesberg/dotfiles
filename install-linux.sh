#!/bin/bash
echo "🐧 Starting Linux Server setup..."

# Security check: Ensure not running as root, but has sudo access
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Run this as your normal user, NOT with sudo or as root!"
    exit 1
fi

mkdir -p ~/.zsh ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# 1. Apt Dependencies
sudo apt update
sudo apt install -y stow tmux zsh curl git ripgrep fd-find unzip build-essential

# 2. Latest Binaries (Neovim & FZF)
echo "Installing Neovim..."
# Corrected Neovim URL for x86_64
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim-linux64
sudo tar -C /opt -xzf nvim-linux64.tar.gz
sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
rm nvim-linux64.tar.gz

echo "Installing FZF..."
# FZF doesn't provide a 'latest' alias in the filename, so we use the git installer 
# which is much more reliable for finding the right version.
if [ ! -d ~/.fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --bin
    cp ~/.fzf/bin/fzf ~/.local/bin/
fi

# 3. Universal Tools
if ! command -v zoxide &> /dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Plugin Clones
[ ! -d ~/.zsh/zsh-autosuggestions ] && git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
[ ! -d ~/.zsh/zsh-syntax-highlighting ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
[ ! -d ~/.zsh/fzf-tab ] && git clone https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 4. Stow Configs
echo "Symlinking dotfiles with Stow..."
mkdir -p "$HOME/.config"
FILES_TO_BACKUP=("$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/nvim")
for file in "${FILES_TO_BACKUP[@]}"; do
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        mv "$file" "${file}.backup"
    fi
done

# Navigate to script directory and stow
cd "$(dirname "${BASH_SOURCE[0]}")"
stow -t ~/ zsh tmux nvim

# Set ZSH as default shell
if [[ "$SHELL" != *"/zsh" ]]; then
    sudo chsh -s $(which zsh) $USER
fi

echo "✅ Linux Setup complete! Please log out and log back in (or run 'zsh')."