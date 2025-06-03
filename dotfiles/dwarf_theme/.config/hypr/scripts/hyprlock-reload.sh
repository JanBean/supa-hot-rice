#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.webp" \) | shuf -n 1