#!/bin/bash

# Define variables
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="mac"

if [[ "$1" == "--server" ]]; then
    MODE="server"
    echo "Starting Server setup (Ubuntu/Debian with root)..."
elif [[ "$1" == "--cluster" ]]; then
    MODE="cluster"
    echo "Starting Cluster setup (Rootless, local binaries)..."
else
    echo "Starting Local Mac setup..."
fi

# Create directory for custom Zsh plugins and local binaries
mkdir -p ~/.zsh
mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# ==========================================
# 1. Install Dependencies based on Environment
# ==========================================

if [ "$MODE" == "server" ]; then
    sudo apt update
    sudo apt install -y stow tmux zsh curl git ripgrep fd-find unzip build-essential fzf zoxide bat
    
    echo "Installing latest Neovim..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux64.tar.gz
    sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux64.tar.gz

elif [ "$MODE" == "cluster" ]; then
    echo "Downloading static binaries to ~/.local/bin..."

    # Neovim
    if ! command -v nvim &> /dev/null; then
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
        rm -rf ~/.local/nvim
        tar -xzf nvim-linux64.tar.gz
        mv nvim-linux64 ~/.local/nvim
        ln -sf ~/.local/nvim/bin/nvim ~/.local/bin/nvim
        rm nvim-linux64.tar.gz
    fi

    # GNU Stow (Compile from source locally)
    if ! command -v stow &> /dev/null; then
        curl -LO https://ftp.gnu.org/gnu/stow/stow-2.3.1.tar.gz
        tar -xzf stow-2.3.1.tar.gz
        cd stow-2.3.1
        ./configure --prefix="$HOME/.local"
        make && make install
        cd .. && rm -rf stow-2.3.1*
    fi

    # Ripgrep (Required for LazyVim Telescope)
    if ! command -v rg &> /dev/null; then
        curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-unknown-linux-musl.tar.gz
        tar -xzf ripgrep-*.tar.gz
        cp ripgrep-*/rg ~/.local/bin/
        rm -rf ripgrep-*
    fi

    # Fd (Required for LazyVim Telescope)
    if ! command -v fd &> /dev/null; then
        curl -LO https://github.com/sharkdp/fd/releases/download/v10.1.0/fd-v10.1.0-x86_64-unknown-linux-musl.tar.gz
        tar -xzf fd-*.tar.gz
        cp fd-*/fd ~/.local/bin/
        rm -rf fd-*
    fi

else
    # Mac Mode
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew update
    brew install stow tmux neovim zsh ripgrep fd starship fzf zoxide eza bat
    brew install zsh-autosuggestions zsh-syntax-highlighting
fi

# ==========================================
# 2. Universal Installations (Cross-Platform)
# ==========================================

# Install Zsh plugins manually if not on Mac
if [ "$MODE" != "mac" ]; then
    if [ ! -d ~/.zsh/zsh-autosuggestions ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    fi
    if [ ! -d ~/.zsh/zsh-syntax-highlighting ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
    fi
fi

# Install Warp-like fzf-tab
if [ ! -d ~/.zsh/fzf-tab ]; then
    git clone https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
fi

# Install Starship prompt (force to local bin for cluster)
if ! command -v starship &> /dev/null; then
    if [ "$MODE" == "cluster" ]; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
    else
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
fi

# Install Tmux Plugin Manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# ==========================================
# 3. Stow Configurations
# ==========================================
echo "Checking for existing config files to prevent Stow conflicts..."
mkdir -p "$HOME/.config"

FILES_TO_BACKUP=("$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/nvim")
for file in "${FILES_TO_BACKUP[@]}"; do
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        echo "Backing up existing $file to ${file}.backup..."
        mv "$file" "${file}.backup"
    fi
done

echo "Symlinking dotfiles with Stow..."
cd "$DOTFILES_DIR"
stow -t ~/ zsh
stow -t ~/ tmux
stow -t ~/ nvim

# 6. Change default shell to Zsh (Will likely fail on cluster, but good to try)
if [[ "$SHELL" != *"/zsh" ]]; then
    echo "Attempting to change default shell to zsh..."
    chsh -s $(which zsh) || echo "Could not change shell automatically. You may need to run 'zsh' manually."
fi

echo "Setup complete! Please restart your terminal or run: source ~/.zshrc"