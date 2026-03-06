#!/bin/bash
echo "🐧 Starting Local Linux setup..."

# 1. Install Dependencies
echo "Installing packages..."
sudo apt update
sudo apt install -y stow tmux neovim zsh ripgrep fd-find starship fzf bat

# fd-find and batcat are named differently on Debian/Ubuntu
mkdir -p ~/.local/bin
[ ! -L ~/.local/bin/fd ] && ln -s "$(which fdfind)" ~/.local/bin/fd 2>/dev/null
[ ! -L ~/.local/bin/bat ] && ln -s "$(which batcat)" ~/.local/bin/bat 2>/dev/null

# Install tools not in default repos
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi
if ! command -v zoxide &> /dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi
if ! command -v eza &> /dev/null; then
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
fi

# zsh plugins (no brew tap available, clone manually)
sudo mkdir -p /usr/share/zsh-autosuggestions /usr/share/zsh-syntax-highlighting
if [ ! -d /usr/share/zsh-autosuggestions/.git ]; then
    sudo git clone https://github.com/zsh-users/zsh-autosuggestions /usr/share/zsh-autosuggestions
fi
if [ ! -d /usr/share/zsh-syntax-highlighting/.git ]; then
    sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting /usr/share/zsh-syntax-highlighting
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

# 4. Change Shell
if [[ "$SHELL" != *"/zsh" ]]; then
    chsh -s "$(which zsh)"
fi
echo "✅ Linux Setup complete! Restart your terminal."