#!/bin/bash
echo "🧹 Starting Cluster uninstallation (Rootless)..."

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

# 4. Remove all locally downloaded static binaries
echo "Removing local binaries from ~/.local/bin..."
rm -rf ~/.local/nvim
rm -f ~/.local/bin/nvim
rm -f ~/.local/bin/stow
rm -f ~/.local/bin/rg
rm -f ~/.local/bin/fd
rm -f ~/.local/bin/fzf
rm -f ~/.local/bin/zoxide
rm -f ~/.local/bin/starship

echo "✅ Cluster uninstallation complete!"