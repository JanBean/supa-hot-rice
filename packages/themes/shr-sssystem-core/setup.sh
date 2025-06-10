load_setup() {
    echo "loading sssystem core setup..."
    if gum confirm --default=true "Set Desktop wallpaper? (Some themes require a Wallpaper)"; then

    DEFAULT_PATH="themes/sssystem-theme/dotfiles/.config/hypr/resources/ruan-jia.jpg"
    wallpaper_path=$(gum input --placeholder "$DEFAULT_PATH" --prompt "Enter path to wallpaper: (default = $DEFAULT_PATH")

    # Fallback if user enters nothing (just presses Enter)
    wallpaper_path="${wallpaper_path:-$DEFAULT_PATH}"
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