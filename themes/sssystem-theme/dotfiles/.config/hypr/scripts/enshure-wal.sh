#!/bin/bash
color_config_path="/home/$USER/.cache/wal/colors-hyprland.conf"
hyprpaper_config_path="/home/$USER/.cache/wal/hyprpaper.conf"
fallback_wallpaper="/home/$USER/.config/hypr/resources/ruan-jia.jpg"
current_wallpaper=""

if [ -r "$color_config_path" ]; then
    current_wallpaper="$(sed -n 's/^\$wallpaper = //p' "$color_config_path" | head -n 1)"
fi

if [ ! -e "$color_config_path" ] \
    || [ ! -e "$hyprpaper_config_path" ] \
    || [ -z "$current_wallpaper" ] \
    || [ ! -e "$current_wallpaper" ]; then
    wal -i "$fallback_wallpaper"
fi