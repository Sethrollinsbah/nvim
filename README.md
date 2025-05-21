# AstroNvim Template

## .tmux.conf

```bash

# Enable mouse support for scrolling

set-option -g mouse on

# Enable vi-style key bindings

set-window-option -g mode-keys vi

# Scroll history with Page Up/Page Down or Shift+Up/Down

bind-key -T copy-mode-vi PageUp send-keys -X page-up
bind-key -T copy-mode-vi PageDown send-keys -X page-down
bind-key -T copy-mode-vi S-Up send-keys -X halfpage-up
bind-key -T copy-mode-vi S-Down send-keys -X halfpage-down

# Easier split pane commands

bind-key v split-window -h
bind-key s split-window -v

# Reload tmux config

bind-key r source-file ~/.tmux.conf \; display-message "Reloaded ~/.tmux.conf"

# Theme management (basic example, extend as needed)

# Define themes as variables

theme_default="#[fg=colour244,bg=colour235] #H #[fg=colour235,bg=colour240] #W #[fg=colour240,bg=colour235] %a %Y-%m-%d %H:%M:%S "
theme_dark="#[fg=colour250,bg=colour234] #H #[fg=colour234,bg=colour238] #W #[fg=colour238,bg=colour234] %a %Y-%m-%d %H:%M:%S "
theme_light="#[fg=black,bg=colour252] #H #[fg=colour252,bg=colour250] #W #[fg=colour250,bg=colour252] %a %Y-%m-%d %H:%M:%S "

# Set default theme

set-option -g status-right "$theme_default"

# Bind keys to change themes

bind-key T command-prompt -p "Theme (default, dark, light): " "run-shell 'change_theme \"%%\"'"

# Example of more comprehensive theme options

# Set base colors

set-option -g default-terminal "tmux-256color"
set-option -ga terminal-overrides ",_256color_:RGB" #Fixes issues with some terminals.

# Status bar styling

set-option -g status-style fg=colour244,bg=colour235
set-option -g status-left-length 40
set-option -g status-left "#[fg=colour255,bg=colour238] #S #[fg=colour238,bg=colour235] "
set-option -g status-right-length 140

# Pane border styling

set-option -g pane-border-style fg=colour238
set-option -g pane-active-border-style fg=colour250

# Message styling

set-option -g message-style fg=colour255,bg=colour235
set-option -g message-command-style fg=colour255,bg=colour235

# Window styling

set-window-option -g window-status-style fg=colour244,bg=colour235
set-window-option -g window-status-current-style fg=colour255,bg=colour238
set-window-option -g window-status-current-format " #[fg=colour255,bg=colour238] #I:#W#F #[fg=colour238,bg=colour235] "
set-window-option -g window-status-format " #[fg=colour244,bg=colour235] #I:#W#F #[fg=colour235,bg=colour235] "

set-option -g renumber-windows on

```

## .zshrc file

````bash

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
echo "Installing zsh-syntax-highlighting..."
git clone <https://github.com/zsh-users/zsh-syntax-highlighting.git> ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
echo "Installing zsh-autosuggestions..."
git clone <https://github.com/zsh-users/zsh-autosuggestions.git> ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

plugins=(
git
bun
gh
github
zsh-autosuggestions
zsh-syntax-highlighting
vi-mode
gnu-utils
git-prompt
dotenv
cp
colorize)

source $ZSH/oh-my-zsh.sh

ZSH_THEME="powerlevel10k/powerlevel10k"

[ -s "/root/.bun/_bun" ] && source "/root/.bun/\_bun"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"```
````
