#!/bin/bash
echo "🧹 Starting Linux Server uninstallation..."

if [ "$EUID" -eq 0 ] && [ "$SUDO_USER" != "" ]; then
    echo "ERROR: Run this as your normal user, NOT with sudo!"
    exit 1
fi

# 1. Unstow configurations
cd "$(dirname "${BASH_SOURCE[0]}")"
if command -v stow &> /dev/null; then
    stow -D -t ~/ zsh tmux nvim
fi

# 2. Restore original backups
FILES_TO_RESTORE=("$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/nvim")
for file in "${FILES_TO_RESTORE[@]}"; do
    if [ -e "${file}.backup" ]; then
        echo "Restoring ${file} from backup..."
        mv "${file}.backup" "$file"
    fi
done

# 3. Remove cloned plugins and caches
echo "Cleaning up plugin directories..."
rm -rf ~/.zsh ~/.tmux ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim

# 4. Remove manually downloaded binaries
echo "Removing manually installed binaries..."
sudo rm -rf /opt/nvim-linux-x86_64
sudo rm -f /usr/local/bin/nvim
rm -f ~/.local/bin/fzf ~/.local/bin/zoxide ~/.local/bin/starship

# 5. Remove apt packages (Keeping git, curl, and zsh as they are system staples)
echo "Removing apt packages..."
sudo apt remove -y stow tmux ripgrep fd-find bat
sudo apt autoremove -y

echo "✅ Linux Server uninstallation complete!"
echo "Note: If you want to change your default shell back to bash, run: chsh -s /bin/bash"