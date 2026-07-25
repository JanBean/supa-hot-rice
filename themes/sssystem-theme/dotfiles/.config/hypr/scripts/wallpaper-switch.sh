#!/usr/bin/env bash
set -euo pipefail

direction="${1:-next}"
base="$HOME/supa-hot-rice"
timer_pid_file="${XDG_RUNTIME_DIR:-/tmp}/shr-wallpaper-submap-timer.pid"

restart_submap_timer() {
  if [[ -r "$timer_pid_file" ]]; then
    kill "$(cat "$timer_pid_file")" 2>/dev/null || true
  fi

  (
    sleep 5
    hyprctl dispatch submap reset >/dev/null 2>&1 || true
    rm -f "$timer_pid_file"
  ) &

  printf '%s\n' "$!" > "$timer_pid_file"
}

source "$base/scriptdata/wallpapers"
load_active_theme_config
resolve_theme_wallpaper_config

wallpapers=()
for wallpaper_dir in "${THEME_WALLPAPER_DIRS[@]}"; do
  [[ -d "$wallpaper_dir" ]] || continue
  while IFS= read -r -d '' wallpaper_file; do
    wallpapers+=("$wallpaper_file")
  done < <(
    find "$wallpaper_dir" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
      -print0 | sort -z
  )
done

if [[ "${#wallpapers[@]}" -eq 0 ]]; then
  wallpapers=("$THEME_FALLBACK_WALLPAPER")
fi

current_wallpaper=""
if [[ -r "$HOME/.cache/wal/colors-hyprland.conf" ]]; then
  current_wallpaper="$(sed -n 's/^\$wallpaper = //p' "$HOME/.cache/wal/colors-hyprland.conf" | head -n 1)"
fi

current_index=-1
for index in "${!wallpapers[@]}"; do
  if [[ "${wallpapers[$index]}" == "$current_wallpaper" ]]; then
    current_index="$index"
    break
  fi
done

case "$direction" in
  previous|prev|left)
    next_index=$(( (current_index - 1 + ${#wallpapers[@]}) % ${#wallpapers[@]} ))
    ;;
  next|right)
    next_index=$(( (current_index + 1) % ${#wallpapers[@]} ))
    ;;
  *)
    printf 'Usage: %s [next|previous]\n' "$0" >&2
    exit 2
    ;;
esac

next_wallpaper="${wallpapers[$next_index]}"

wal -i "$next_wallpaper"

pkill hyprpaper 2>/dev/null || true
setsid hyprpaper -c "$HOME/.cache/wal/hyprpaper.conf" >/tmp/hyprpaper.log 2>&1 < /dev/null &

pkill waybar 2>/dev/null || true
setsid waybar >/tmp/waybar.log 2>&1 < /dev/null &

hyprctl reload >/dev/null 2>&1 || true
hyprctl dispatch submap wallpaper >/dev/null 2>&1 || true
restart_submap_timer
