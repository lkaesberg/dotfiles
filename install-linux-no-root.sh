#!/bin/bash
echo "🐧 Starting Local Linux setup (no root)..."

export PATH="$HOME/.local/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"

mkdir -p ~/.local/bin ~/.local/src

# --- Helper: build local libs needed by tmux ---
build_libevent() {
    echo "Building libevent..."
    cd /tmp
    curl -LO https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz
    tar xzf libevent-2.1.12-stable.tar.gz
    cd libevent-2.1.12-stable
    ./configure --prefix="$HOME/.local" --disable-shared
    make && make install
    cd /tmp && rm -rf libevent-*
}

build_ncurses() {
    echo "Building ncurses..."
    cd /tmp
    curl -LO https://ftp.gnu.org/gnu/ncurses/ncurses-6.5.tar.gz
    tar xzf ncurses-6.5.tar.gz
    cd ncurses-6.5
    ./configure --prefix="$HOME/.local" --with-shared --without-debug --without-ada
    make && make install
    cd /tmp && rm -rf ncurses-*
}

# 1. tmux (build from source with local deps)
if ! command -v tmux &> /dev/null || [[ "$(tmux -V | grep -oP '\d+\.\d+')" < "3.2" ]]; then
    echo "Installing tmux 3.5a from source..."
    [ ! -f "$HOME/.local/lib/libevent.a" ] && build_libevent
    [ ! -f "$HOME/.local/lib/libncurses.a" ] && build_ncurses
    cd /tmp
    curl -LO https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz
    tar xzf tmux-3.5a.tar.gz
    cd tmux-3.5a
    PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig" \
    CFLAGS="-I$HOME/.local/include -I$HOME/.local/include/ncurses" \
    LDFLAGS="-L$HOME/.local/lib" \
    ./configure --prefix="$HOME/.local"
    make && make install
    cd /tmp && rm -rf tmux-*
fi

# 2. Neovim — build from source into ~/.local
if ! command -v nvim &> /dev/null || [[ "$(nvim --version | head -1 | grep -oP '\d+\.\d+')" < "0.9" ]]; then
    echo "Installing Neovim from source..."
    cd /tmp
    git clone https://github.com/neovim/neovim.git /tmp/neovim-build
    cd /tmp/neovim-build
    git checkout stable
    make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$HOME/.local"
    make install
    cd /tmp && rm -rf neovim-build
fi

# 3. Starship
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin
fi

# 4. Zoxide
if ! command -v zoxide &> /dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# 5. fzf
if ! command -v fzf &> /dev/null; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --bin
    ln -sf ~/.fzf/bin/fzf ~/.local/bin/fzf
fi

# 6. ripgrep (static musl binary)
if ! command -v rg &> /dev/null; then
    echo "Installing ripgrep..."
    RG_VERSION=$(curl -sL https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')
    curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    tar xzf "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    cp "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" ~/.local/bin/
    rm -rf "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl"*
fi

# 7. fd (static musl binary)
if ! command -v fd &> /dev/null && ! command -v fdfind &> /dev/null; then
    echo "Installing fd..."
    FD_VERSION=$(curl -sL https://api.github.com/repos/sharkdp/fd/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
    curl -LO "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    tar xzf "fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    cp "fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd" ~/.local/bin/
    rm -rf "fd-v${FD_VERSION}-x86_64-unknown-linux-musl"*
fi

# 8. bat (static musl binary)
if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
    echo "Installing bat..."
    BAT_VERSION=$(curl -sL https://api.github.com/repos/sharkdp/bat/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
    curl -LO "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    tar xzf "bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    cp "bat-v${BAT_VERSION}-x86_64-unknown-linux-musl/bat" ~/.local/bin/
    rm -rf "bat-v${BAT_VERSION}-x86_64-unknown-linux-musl"*
fi

# 9. eza (static musl binary)
if ! command -v eza &> /dev/null; then
    echo "Installing eza..."
    EZA_VERSION=$(curl -sL https://api.github.com/repos/eza-community/eza/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
    curl -LO "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz"
    tar xzf "eza_x86_64-unknown-linux-musl.tar.gz"
    mv eza ~/.local/bin/
    rm -f "eza_x86_64-unknown-linux-musl.tar.gz"
fi

# 10. stow (perl-based, no compiled deps)
if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    cd /tmp
    STOW_VERSION="2.4.1"
    curl -LO "https://ftp.gnu.org/gnu/stow/stow-${STOW_VERSION}.tar.gz"
    tar xzf "stow-${STOW_VERSION}.tar.gz"
    cd "stow-${STOW_VERSION}"
    ./configure --prefix="$HOME/.local"
    make && make install
    cd /tmp && rm -rf "stow-${STOW_VERSION}"*
fi

# 11. Zsh plugins
mkdir -p ~/.local/share/zsh-plugins
if [ ! -d ~/.local/share/zsh-plugins/zsh-autosuggestions ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.local/share/zsh-plugins/zsh-autosuggestions
fi
if [ ! -d ~/.local/share/zsh-plugins/zsh-syntax-highlighting ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.local/share/zsh-plugins/zsh-syntax-highlighting
fi

# 12. Universal Tools
mkdir -p ~/.zsh
if [ ! -d ~/.zsh/fzf-tab ]; then
    git clone https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
fi
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# 13. Stow Configs
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

# 14. Change Shell
if [[ "$SHELL" != *"/zsh" ]]; then
    ZSH_PATH=$(which zsh 2>/dev/null)
    if [ -n "$ZSH_PATH" ]; then
        chsh -s "$ZSH_PATH" 2>/dev/null || {
            echo "⚠️  Can't change shell without root. Add this to your .bashrc:"
            echo "    [[ -t 1 ]] && exec $ZSH_PATH"
        }
    else
        echo "⚠️  zsh not found. Ask your admin to install it."
    fi
fi

echo "✅ Linux Setup complete (no root)! Restart your terminal."
echo ""
echo "Make sure these are in your .zshrc:"
echo '  export PATH="$HOME/.local/bin:$PATH"'
echo '  export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'