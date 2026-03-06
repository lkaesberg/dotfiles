#!/bin/bash
echo "🍏 Starting Local Mac setup..."

# 1. Install Dependencies
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew update
brew install stow tmux neovim zsh ripgrep fd starship fzf zoxide eza bat
brew install zsh-autosuggestions zsh-syntax-highlighting

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
    chsh -s $(which zsh)
fi
echo "✅ Mac Setup complete! Restart your terminal."