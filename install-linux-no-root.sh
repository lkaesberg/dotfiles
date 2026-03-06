#!/bin/bash
echo "🐧 Starting Local Linux setup (no root)..."

export PATH="$HOME/.local/bin:$PATH"

# 1. Install Dependencies (all to ~/.local)
mkdir -p ~/.local/bin ~/.local/src

# Neovim — build from source into ~/.local
if ! command -v nvim &> /dev/null || [[ "$(nvim --version | head -1 | grep -oP '\d+\.\d+')" < "0.9" ]]; then
    echo "Installing Neovim from source..."
    # build deps should already be available; if not, this won't work without root
    git clone https://github.com/neovim/neovim.git /tmp/neovim-build
    cd /tmp/neovim-build
    git checkout stable
    make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$HOME/.local"
    make install
    cd -
    rm -rf /tmp/neovim-build
fi

# Starship
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin
fi

# Zoxide
if ! command -v zoxide &> /dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# fzf
if ! command -v fzf &> /dev/null; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --bin
    ln -sf ~/.fzf/bin/fzf ~/.local/bin/fzf
fi

# ripgrep
if ! command -v rg &> /dev/null; then
    echo "Installing ripgrep..."
    RG_VERSION=$(curl -sL https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')
    curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    tar xzf "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    cp "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" ~/.local/bin/
    rm -rf "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl"*
fi

# fd
if ! command -v fd &> /dev/null && ! command -v fdfind &> /dev/null; then
    echo "Installing fd..."
    FD_VERSION=$(curl -sL https://api.github.com/repos/sharkdp/fd/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
    curl -LO "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    tar xzf "fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    cp "fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd" ~/.local/bin/
    rm -rf "fd-v${FD_VERSION}-x86_64-unknown-linux-musl"*
fi

# bat
if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
    echo "Installing bat..."
    BAT_VERSION=$(curl -sL https://api.github.com/repos/sharkdp/bat/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
    curl -LO "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    tar xzf "bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    cp "bat-v${BAT_VERSION}-x86_64-unknown-linux-musl/bat" ~/.local/bin/
    rm -rf "bat-v${BAT_VERSION}-x86_64-unknown-linux-musl"*
fi

# eza
if ! command -v eza &> /dev/null; then
    echo "Installing eza..."
    EZA_VERSION=$(curl -sL https://api.github.com/repos/eza-community/eza/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
    curl -LO "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz"
    tar xzf "eza_x86_64-unknown-linux-musl.tar.gz"
    mv eza ~/.local/bin/
    rm -f "eza_x86_64-unknown-linux-musl.tar.gz"
fi

# tmux (build from source if not available)
if ! command -v tmux &> /dev/null; then
    echo "Installing tmux from source..."
    TMUX_VERSION=$(curl -sL https://api.github.com/repos/tmux/tmux/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')
    curl -LO "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
    tar xzf "tmux-${TMUX_VERSION}.tar.gz"
    cd "tmux-${TMUX_VERSION}"
    ./configure --prefix="$HOME/.local"
    make && make install
    cd -
    rm -rf "tmux-${TMUX_VERSION}"*
fi

# stow (perl-based, builds easily without root)
if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    STOW_VERSION="2.4.1"
    curl -LO "https://ftp.gnu.org/gnu/stow/stow-${STOW_VERSION}.tar.gz"
    tar xzf "stow-${STOW_VERSION}.tar.gz"
    cd "stow-${STOW_VERSION}"
    ./configure --prefix="$HOME/.local"
    make && make install
    cd -
    rm -rf "stow-${STOW_VERSION}"*
fi

# Zsh plugins
mkdir -p ~/.local/share/zsh-plugins
if [ ! -d ~/.local/share/zsh-plugins/zsh-autosuggestions ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.local/share/zsh-plugins/zsh-autosuggestions
fi
if [ ! -d ~/.local/share/zsh-plugins/zsh-syntax-highlighting ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.local/share/zsh-plugins/zsh-syntax-highlighting
fi

# 2. Universal Tools
mkdir -p ~/.zsh
if [ ! -d ~/.zsh/fzf-tab ]; then
    git clone https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
fi
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

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

# 4. Change Shell (suggest manual if chsh needs root)
if [[ "$SHELL" != *"/zsh" ]]; then
    ZSH_PATH=$(which zsh 2>/dev/null)
    if [ -n "$ZSH_PATH" ]; then
        chsh -s "$ZSH_PATH" 2>/dev/null || echo "⚠️  Can't change shell without root. Add this to your .bashrc instead:"
        echo "    exec $ZSH_PATH -l"
    else
        echo "⚠️  zsh not found. Ask your admin to install it, or add ~/.local/bin to PATH and install from source."
    fi
fi

echo "✅ Linux Setup complete (no root)! Restart your terminal."
echo "Make sure ~/.local/bin is in your PATH."