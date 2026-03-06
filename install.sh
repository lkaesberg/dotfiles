#!/bin/bash

# Define variables
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_MODE=0

if [[ "$1" == "--server" ]]; then
    SERVER_MODE=1
    echo "Starting Server setup (Ubuntu/Debian)..."
else
    echo "Starting Local Mac setup..."
fi

# Create directory for custom Zsh plugins
mkdir -p ~/.zsh

# 1. Install Dependencies
if [ $SERVER_MODE -eq 1 ]; then
    sudo apt update
    sudo apt install -y stow tmux zsh curl git ripgrep fd-find unzip build-essential fzf zoxide bat
    
    # Servers often have old Neovim versions. LazyVim requires >= 0.9.0.
    echo "Installing latest Neovim..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux64.tar.gz
    sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux64.tar.gz

    # Install Zsh plugins manually for Linux
    echo "Installing Zsh plugins for Server..."
    if [ ! -d ~/.zsh/zsh-autosuggestions ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    fi
    if [ ! -d ~/.zsh/zsh-syntax-highlighting ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
    fi
else
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew update
    
    # Install power-user tools
    brew install stow tmux neovim zsh ripgrep fd starship fzf zoxide eza bat
    
    # Install Mac-specific Zsh plugins
    brew install zsh-autosuggestions zsh-syntax-highlighting
fi

# Install Warp-like fzf-tab (both Mac and Server)
if [ ! -d ~/.zsh/fzf-tab ]; then
    echo "Installing fzf-tab..."
    git clone https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
fi

# 2. Install Starship prompt (cross-platform way for the server)
if [ $SERVER_MODE -eq 1 ] && ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# 3. Install Tmux Plugin Manager (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# 4. Backup existing files to prevent Stow conflicts
echo "Checking for existing config files to prevent Stow conflicts..."
mkdir -p "$HOME/.config"

FILES_TO_BACKUP=("$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/nvim")

for file in "${FILES_TO_BACKUP[@]}"; do
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        echo "Backing up existing $file to ${file}.backup..."
        mv "$file" "${file}.backup"
    fi
done

# 5. Stow configurations
echo "Symlinking dotfiles with Stow..."
cd "$DOTFILES_DIR"
stow -t ~/ zsh
stow -t ~/ tmux
stow -t ~/ nvim

# 6. Change default shell to Zsh if it isn't already
if [[ "$SHELL" != *"/zsh" ]]; then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
fi

echo "Setup complete! Please restart your terminal or run: source ~/.zshrc"