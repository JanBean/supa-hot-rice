load_setup() {
    echo "loading sssystem core setup..."
    if gum confirm --default=true "Set Desktop wallpaper? (Some themes require a Wallpaper)"; then
    wallpaper_path=$(gum input --placeholder "Enter path to wallpaper")
    if [ -n "$wallpaper_path" ]; then
      ask_execute wal -i "$wallpaper_path"
    else
      echo "No path specified, continuing symlinking dotfiles"
    fi
  fi
}

unload_setup() {
  echo "Unloading shr sssystem core setup..."
}