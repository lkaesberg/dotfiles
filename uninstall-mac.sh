#!/bin/bash
echo "🧹 Starting Mac uninstallation..."

# 1. Unstow configurations (Removes the symlinks)
cd "$(dirname "${BASH_SOURCE[0]}")"
if command -v stow &> /dev/null; then
    stow -D -t ~/ zsh tmux nvim
fi

# 2. Restore original backups if they exist
FILES_TO_RESTORE=("$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/nvim")
for file in "${FILES_TO_RESTORE[@]}"; do
    if [ -e "${file}.backup" ]; then
        echo "Restoring ${file} from backup..."
        mv "${file}.backup" "$file"
    fi
done

# 3. Remove cloned plugins and caches
echo "Cleaning up plugin directories..."
rm -rf ~/.zsh
rm -rf ~/.tmux
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim

# 4. Uninstall Homebrew packages
echo "Uninstalling Homebrew packages..."
brew uninstall stow tmux neovim ripgrep fd starship fzf zoxide eza bat zsh-autosuggestions zsh-syntax-highlighting

echo "✅ Mac uninstallation complete!"
echo "Note: If you want to change your default shell back to bash, run: chsh -s /bin/bash"