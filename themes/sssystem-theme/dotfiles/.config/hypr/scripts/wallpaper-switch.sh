#!/usr/bin/env bash
set -euo pipefail

direction="${1:-next}"
base="$HOME/supa-hot-rice"
timer_pid_file="${XDG_RUNTIME_DIR:-/tmp}/shr-wallpaper-submap-timer.pid"
wal_colors_file="$HOME/.cache/wal/colors-hyprland.conf"
hyprpaper_config="$HOME/.cache/wal/hyprpaper.conf"

wallpapers=()
wallpaper_dirs_by_index=()
available_dirs=()

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

add_wallpapers_from_dir() {
  local wallpaper_dir="$1"
  local wallpapers_before="${#wallpapers[@]}"
  local wallpaper_file

  [[ -d "$wallpaper_dir" ]] || return 0

  while IFS= read -r -d '' wallpaper_file; do
    wallpapers+=("$wallpaper_file")
    wallpaper_dirs_by_index+=("$wallpaper_dir")
  done < <(
    find "$wallpaper_dir" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
      -print0 | sort -z
  )

  if [[ "${#wallpapers[@]}" -gt "$wallpapers_before" ]]; then
    available_dirs+=("$wallpaper_dir")
  fi
}

load_wallpapers() {
  local wallpaper_dir
  local fallback_dir

  for wallpaper_dir in "${THEME_WALLPAPER_DIRS[@]}"; do
    add_wallpapers_from_dir "$wallpaper_dir"
  done

  if [[ "${#wallpapers[@]}" -gt 0 ]]; then
    return
  fi

  fallback_dir="$(dirname "$THEME_FALLBACK_WALLPAPER")"
  wallpapers=("$THEME_FALLBACK_WALLPAPER")
  wallpaper_dirs_by_index=("$fallback_dir")
  available_dirs=("$fallback_dir")
}

current_wallpaper() {
  [[ -r "$wal_colors_file" ]] || return 0
  sed -n 's/^\$wallpaper = //p' "$wal_colors_file" | head -n 1
}

wallpaper_index() {
  local wallpaper="$1"
  local index

  for index in "${!wallpapers[@]}"; do
    if [[ "${wallpapers[$index]}" == "$wallpaper" ]]; then
      printf '%s\n' "$index"
      return 0
    fi
  done

  printf '%s\n' "-1"
}

current_dir() {
  local current_index="$1"

  if [[ "$current_index" -ge 0 ]]; then
    printf '%s\n' "${wallpaper_dirs_by_index[$current_index]}"
    return
  fi

  printf '%s\n' "${available_dirs[0]}"
}

dir_position() {
  local directory="$1"
  local position

  for position in "${!available_dirs[@]}"; do
    if [[ "${available_dirs[$position]}" == "$directory" ]]; then
      printf '%s\n' "$position"
      return 0
    fi
  done

  printf '%s\n' "0"
}

wallpaper_indexes_in_dir() {
  local directory="$1"
  local index

  for index in "${!wallpapers[@]}"; do
    if [[ "${wallpaper_dirs_by_index[$index]}" == "$directory" ]]; then
      printf '%s\n' "$index"
    fi
  done
}

first_wallpaper_index_in_dir() {
  local directory="$1"
  local index

  for index in "${!wallpapers[@]}"; do
    if [[ "${wallpaper_dirs_by_index[$index]}" == "$directory" ]]; then
      printf '%s\n' "$index"
      return 0
    fi
  done

  printf '%s\n' "0"
}

next_wallpaper_in_dir() {
  local directory="$1"
  local current_index="$2"
  local step="$3"
  local dir_indexes=()
  local position
  local current_position="-1"
  local next_position

  while IFS= read -r position; do
    dir_indexes+=("$position")
  done < <(wallpaper_indexes_in_dir "$directory")

  for position in "${!dir_indexes[@]}"; do
    if [[ "${dir_indexes[$position]}" -eq "$current_index" ]]; then
      current_position="$position"
      break
    fi
  done

  if [[ "$current_position" -lt 0 && "$step" -lt 0 ]]; then
    current_position=0
  fi

  next_position=$(( (current_position + step + ${#dir_indexes[@]}) % ${#dir_indexes[@]} ))
  printf '%s\n' "${dir_indexes[$next_position]}"
}

next_wallpaper_dir() {
  local directory="$1"
  local step="$2"
  local current_position
  local next_position

  current_position="$(dir_position "$directory")"
  next_position=$(( (current_position + step + ${#available_dirs[@]}) % ${#available_dirs[@]} ))
  printf '%s\n' "${available_dirs[$next_position]}"
}

resolve_next_index() {
  local current_index="$1"
  local directory="$2"
  local next_dir

  case "$direction" in
    previous|prev|left)
      next_wallpaper_in_dir "$directory" "$current_index" -1
      ;;
    next|right)
      next_wallpaper_in_dir "$directory" "$current_index" 1
      ;;
    previous-dir|prev-dir|up)
      next_dir="$(next_wallpaper_dir "$directory" -1)"
      first_wallpaper_index_in_dir "$next_dir"
      ;;
    next-dir|down)
      next_dir="$(next_wallpaper_dir "$directory" 1)"
      first_wallpaper_index_in_dir "$next_dir"
      ;;
    *)
      printf 'Usage: %s [next|previous|next-dir|previous-dir]\n' "$0" >&2
      exit 2
      ;;
  esac
}

apply_wallpaper() {
  local wallpaper="$1"

  wal -i "$wallpaper"

  pkill hyprpaper 2>/dev/null || true
  setsid hyprpaper -c "$hyprpaper_config" >/tmp/hyprpaper.log 2>&1 < /dev/null &

  pkill waybar 2>/dev/null || true
  setsid waybar >/tmp/waybar.log 2>&1 < /dev/null &

  hyprctl reload >/dev/null 2>&1 || true
  hyprctl dispatch submap wallpaper >/dev/null 2>&1 || true
  restart_submap_timer
}

main() {
  local current_index
  local directory
  local next_index

  source "$base/scriptdata/wallpapers"
  load_active_theme_config
  resolve_theme_wallpaper_config
  load_wallpapers

  current_index="$(wallpaper_index "$(current_wallpaper)")"
  directory="$(current_dir "$current_index")"
  next_index="$(resolve_next_index "$current_index" "$directory")"

  apply_wallpaper "${wallpapers[$next_index]}"
}

main
