#!/bin/bash
cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/functions
source ./manager/package-manager

set -e

command -v gum || { echo "\"gum\" not found. This script only works if gum is installed. Aborting..."; exit 1 ; }

theme="$1"
theme_dir="themes/$theme"
conf_file="$theme_dir/theme.conf"

TARGET="$HOME"

if [[ -z "$theme" ]]; then
    echo "Usage: $0 <theme-name>"
    exit 1
fi

if [[ ! -f "$conf_file" ]]; then
    echo "Missing config for theme: $theme"
    exit 1
fi

# Load package names from config
source "$conf_file"

# Unstow theme
echo ":: Preparing to unstow '$theme_dir'"
ask_execute stow -D dotfiles -d "$theme_dir" -t "$TARGET"

# remove theme related packages
if [[ "${#packages[@]}" -gt 0 ]] && gum confirm --default=false "Do you want to remove packages installed by this theme?"; then
    ask_execute uninstall_theme_packages "${packages[@]}"
fi

echo ":: Theme '$theme' has been uninstalled."