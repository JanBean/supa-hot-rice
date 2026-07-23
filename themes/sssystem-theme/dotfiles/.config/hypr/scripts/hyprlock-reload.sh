#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
FALLBACK_WALLPAPER="$(sed -n 's/^\$wallpaper = //p' "$HOME/.cache/wal/colors-hyprland.conf" | head -n 1)"

if [ -d "$WALLPAPER_DIR" ]; then
    wallpaper="$(find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.webp" \) | shuf -n 1)"
fi

if [ -n "$wallpaper" ]; then
    printf '%s\n' "$wallpaper"
elif [ -n "$FALLBACK_WALLPAPER" ] && [ -e "$FALLBACK_WALLPAPER" ]; then
    printf '%s\n' "$FALLBACK_WALLPAPER"
fi
