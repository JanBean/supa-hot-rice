load_setup() {
  echo "loading sssystem core setup..."

  if ! declare -F resolve_theme_wallpaper_config >/dev/null; then
    source "$base/scriptdata/wallpapers"
  fi

  resolve_theme_wallpaper_config

  if [ -n "$THEME_WALLPAPER" ]; then
    ask_execute wal -i "$THEME_WALLPAPER"
  else
    echo "No wallpaper configured for this theme."
  fi
}

unload_setup() {
  echo "Unloading shr sssystem core setup..."
}
