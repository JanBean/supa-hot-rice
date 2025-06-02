#!/bin/bash
is_magic_active=$(hyprctl activewindow | grep -v Window | grep -Po "workspace\:[^\n]*special\:magic")

if [[ -n "$is_magic_active" ]]; then
    # In special:magic, move window to previous workspace and switch
    hyprctl dispatch movetoworkspace +0
    hyprctl dispatch togglespecialworkspace magic
else
    # Not in special:magic, move window to magic and switch
    hyprctl dispatch movetoworkspace special:magic
    hyprctl dispatch togglespecialworkspace magic
fi