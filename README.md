# AstroNvim Template

```bash
# .tmux.conf

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

````bash
# .zshrc file

# If you come from bash you might have to change your $PATH

# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation

export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will

# load a random theme each time Oh My Zsh is loaded, in which case

# to know which specific one was loaded, run: echo $RANDOM_THEME

# See <https://github.com/ohmyzsh/ohmyzsh/wiki/Themes>

ZSH_THEME="robbyrussell"

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
echo "Installing zsh-syntax-highlighting..."
git clone <https://github.com/zsh-users/zsh-syntax-highlighting.git> ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
echo "Installing zsh-autosuggestions..."
git clone <https://github.com/zsh-users/zsh-autosuggestions.git> ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# Set list of themes to pick from when loading at random

# Setting this variable when ZSH_THEME=random will cause zsh to load

# a theme from this variable instead of looking in $ZSH/themes/

# If set to an empty array, this variable will have no effect

# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion

# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion

# Case-sensitive completion must be off. \_ and - will be interchangeable

# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior

# zstyle ':omz:update' mode disabled # disable automatic updates

# zstyle ':omz:update' mode auto # update automatically without asking

# zstyle ':omz:update' mode reminder # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days)

# zstyle ':omz:update' frequency 13

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

# bun completions

[ -s "/root/.bun/_bun" ] && source "/root/.bun/\_bun"

# bun

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"```
````
