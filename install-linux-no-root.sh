#!/bin/bash
echo "🔒 Starting Cluster setup (Rootless)..."

mkdir -p ~/.zsh ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# 1. Download Static Binaries
echo "Downloading tools to ~/.local/bin..."

# Neovim
if ! command -v nvim &> /dev/null; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    rm -rf ~/.local/nvim
    tar -xzf nvim-linux-x86_64.tar.gz
    mv nvim-linux-x86_64 ~/.local/nvim
    ln -sf ~/.local/nvim/bin/nvim ~/.local/bin/nvim
    rm nvim-linux-x86_64.tar.gz
fi

# GNU Stow (Compile from source)
if ! command -v stow &> /dev/null; then
    curl -LO https://ftp.gnu.org/gnu/stow/stow-2.3.1.tar.gz
    tar -xzf stow-2.3.1.tar.gz
    cd stow-2.3.1
    ./configure --prefix="$HOME/.local"
    make && make install
    cd .. && rm -rf stow-2.3.1*
fi

# Ripgrep & fd & fzf
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-unknown-linux-musl.tar.gz
tar -xzf ripgrep-*.tar.gz && cp ripgrep-*/rg ~/.local/bin/ && rm -rf ripgrep-*

curl -LO https://github.com/sharkdp/fd/releases/download/v10.1.0/fd-v10.1.0-x86_64-unknown-linux-musl.tar.gz
tar -xzf fd-*.tar.gz && cp fd-*/fd ~/.local/bin/ && rm -rf fd-*

curl -LO https://github.com/junegunn/fzf/releases/latest/download/fzf-linux-amd64.tar.gz
tar -xzf fzf-linux-amd64.tar.gz -C ~/.local/bin/ && rm fzf-linux-amd64.tar.gz

# 2. Universal Tools
if ! command -v zoxide &> /dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi

[ ! -d ~/.zsh/zsh-autosuggestions ] && git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
[ ! -d ~/.zsh/zsh-syntax-highlighting ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
[ ! -d ~/.zsh/fzf-tab ] && git clone https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 3. Stow Configs
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

echo "✅ Cluster Setup complete! Run 'zsh' to start."