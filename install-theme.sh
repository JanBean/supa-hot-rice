#!/bin/bash
cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/functions
source ./manager/package-manager

set -e

theme="$1"
theme_dir="themes/$theme"
conf_file="$theme_dir/theme.conf"

TARGET="$HOME"

if [[ ! -f "$conf_file" ]]; then
    echo "Missing config for theme: $theme"
    exit 1
fi

# Load required package names
source "$conf_file"
ask_execute install_theme_packages "${packages[@]}"

#stow theme
echo ":: Preparing to stow '$dir'"
ask_execute stow dotfiles -d "$theme_dir" -t "$TARGET" --adopt # stow dir to target and adopt existing files
if gum confirm --default=false "Git diff to compare adopted and committed files?"; then
  ask_execute git diff
fi
if gum confirm --default=true "Discard adopted files and revert back to contents from last commit?"; then
  ask_execute git reset --hard # Discard adopted file and revert back to contents as per last commit
fi
echo ":: Done stowing selected dotfiles."