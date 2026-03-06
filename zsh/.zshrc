# Start Starship prompt
eval "$(starship init zsh)"

# Better history management
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt hist_ignore_all_dups

# ---------------------------------------------------------
# Warp-like Visual Menus (FZF styling & Completion)
# ---------------------------------------------------------
# Make FZF look like a sleek popup menu instead of full screen
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --margin=1,2"

# Basic Zsh visual menu (allows arrow keys in standard completion)
zstyle ':completion:*' menu select

# Initialize the Zsh completion engine (REQUIRED for fzf-tab)
autoload -Uz compinit
compinit

# Load fzf-tab (replaces standard tab completion with an interactive list)
if [ -f ~/.zsh/fzf-tab/fzf-tab.plugin.zsh ]; then
    source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh
fi

# Set up fzf key bindings and fuzzy completion
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# Set up zoxide (type 'z' instead of 'cd')
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ---------------------------------------------------------
# Aliases
# ---------------------------------------------------------
alias vim="nvim"
alias v="nvim"
alias nano="nvim"

# Use eza if installed, fallback to normal ls
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons=always --color=always"
  alias ll="eza -lah --icons=always --color=always"
  alias tree="eza --tree --icons=always"
else
  alias ls="ls --color=auto"
  alias ll="ls -lah"
fi

# Use bat if installed, fallback to normal cat
if command -v bat >/dev/null 2>&1; then
  alias cat="bat"
fi

# ---------------------------------------------------------
# OS Specific Plugins (Autosuggestions & Syntax Highlighting)
# ---------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS paths (Homebrew)
    source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux Server paths
    if [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
        source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
    fi
    if [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi
fi