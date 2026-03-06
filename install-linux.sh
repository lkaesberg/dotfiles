#!/bin/bash
echo "🐧 Starting Linux Server setup (with sudo)..."

if [ "$EUID" -eq 0 ] && [ "$SUDO_USER" != "" ]; then
    echo "ERROR: Run this as your normal user, NOT with sudo!"
    exit 1
fi

mkdir -p ~/.zsh ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# 1. Apt Dependencies (Removed fzf and zoxide to install them manually)
sudo apt update
sudo apt install -y stow tmux zsh curl git ripgrep fd-find unzip build-essential

# 2. Latest Binaries (Neovim & FZF)
echo "Installing Neovim & FZF..."
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

curl -LO https://github.com/junegunn/fzf/releases/latest/download/fzf-linux-amd64.tar.gz
tar -xzf fzf-linux-amd64.tar.gz -C ~/.local/bin/
rm fzf-linux-amd64.tar.gz

# 3. Universal Tools
if ! command -v zoxide &> /dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi
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

if [[ "$SHELL" != *"/zsh" ]]; then
    chsh -s $(which zsh)
fi
echo "✅ Linux Setup complete! Restart your terminal."