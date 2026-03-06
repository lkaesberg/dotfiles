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
# Using your verified link
curl -LO https://github.com/neovim/neovim/releases/download/latest/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

echo "Installing FZF..."
# This method pulls the actual latest version string from GitHub API to avoid the 404 error
FZF_VERSION=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
curl -LO "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION/v/}-linux_amd64.tar.gz"
tar -xzf "fzf-${FZF_VERSION/v/}-linux_amd64.tar.gz" -C ~/.local/bin/
rm "fzf-${FZF_VERSION/v/}-linux_amd64.tar.gz"

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

cd "$(dirname "${BASH_SOURCE[0]}")"
stow -t ~/ zsh tmux nvim

# Set ZSH as default shell
if [[ "$SHELL" != *"/zsh" ]]; then
    sudo chsh -s $(which zsh) $USER
fi

echo "✅ Linux Setup complete! Please log out and log back in."